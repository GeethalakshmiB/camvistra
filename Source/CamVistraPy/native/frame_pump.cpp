// Native frame pipeline: FrameSlot, CaptureFlag and FramePump.
//
// Port of the per-frame parts of CamVistra/Controller/src/PreviewController.cpp
// (getUsbFrame / getNetworkFrame / processFrameThreadFunc / processFrames) and
// of the frame buffer half of CamVistra/Controls/OpenGlDisplay.cpp. The pixel
// path never enters Python: frames go SDK -> queue -> FrameSlot, and Python is
// only called once per frame (repaint request) and once per stream start
// (format detected). Latency samples are collected here and fetched in
// batches (takeLatencySamples), and USB frame buffers are recycled instead
// of being allocated per frame.
#include "common.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <queue>
#include <thread>

#include "CAMSDK.h"
#include "INetStream.h"

namespace {

// Pixelformat values from CamVistra/Controls/OpenGlDisplay.h.
enum Pixelformat {
    PF_NONE = 0, UYVY = 1, Y16 = 2, RGB32 = 3, YUYV = 4, Y8 = 5, MJPG = 6, Y12 = 7,
    BY8 = 8, BY10 = 9, BY12 = 10, H264 = 11, YUV420 = 12, HEVC = 13, BY16 = 14,
    NV12 = 15, Y10 = 16
};

long long now_epoch_ms() {
    using namespace std::chrono;
    return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
}

void report_callback_error(const char* where) {
    // Called with the GIL held after a Python callback raised.
    PyErr_WriteUnraisable(py::str(where).ptr());
}

}  // namespace

// ---------------------------------------------------------------------------
// FrameSlot: the frame buffer shared by the processing thread (writer) and the
// Qt Quick render thread (reader). Mirrors OpenGLDisplay::srcBuffer & friends.
// GL resources are *not* touched here; when the buffer is re-initialised the
// slot raises `needsReset` and the renderer rebuilds its GL state on the
// render thread (the C++ code freed GL objects from threads without a
// current context).
// ---------------------------------------------------------------------------
class FrameSlot {
  public:
    std::mutex mtx;
    std::vector<uint8_t> buf;
    bool gotFrame = false;
    int width = 0, height = 0, pixfmt = PF_NONE;
    bool needsReset = false;
    std::atomic<bool> fboInitialized{false};
    std::atomic<unsigned long long> framesWritten{0};

    int initDrawBuffer(size_t size) {
        std::lock_guard<std::mutex> lock(mtx);
        needsReset = true;
        gotFrame = false;
        if (buf.size() != size) buf.resize(size);
        return 1;
    }
    int setData(int w, int h, int fmt) {
        std::lock_guard<std::mutex> lock(mtx);
        if (w <= 0 || h <= 0) return 0;
        width = w; height = h; pixfmt = fmt;
        return 1;
    }
    int displayVideoFrame(const uint8_t* data, size_t size) {
        std::lock_guard<std::mutex> lock(mtx);
        if (data == nullptr || buf.empty() || buf.size() != size) return 0;
        std::memcpy(buf.data(), data, size);
        gotFrame = true;
        ++framesWritten;
        return 1;
    }
    int stopFrame() {
        std::lock_guard<std::mutex> lock(mtx);
        gotFrame = false;
        return 1;
    }
    bool clean() {
        std::lock_guard<std::mutex> lock(mtx);
        buf.clear();
        buf.shrink_to_fit();
        gotFrame = false;
        needsReset = true;
        return true;
    }
};

// Shared "capture requested" flag + condition variable (PreviewController's
// captureImage / stillCaptureCond, which are shared by every camera).
class CaptureFlag {
  public:
    std::mutex mtx;
    std::condition_variable cond;
    std::atomic<bool> value{false};

    void set(bool v) {
        { std::lock_guard<std::mutex> lock(mtx); value = v; }
        cond.notify_all();
    }
    void notify() { cond.notify_all(); }
};

// ---------------------------------------------------------------------------
// FramePump: one per open camera (CameraContext's grab/process threads).
// ---------------------------------------------------------------------------
class FramePump {
  public:
    using Grabber = std::function<int(Frame*)>;

    FramePump(py::object source, std::shared_ptr<FrameSlot> slot, std::shared_ptr<CaptureFlag> capture,
              bool network)
        : source_(std::move(source)), slot_(std::move(slot)), capture_(std::move(capture)), network_(network) {
        if (py::isinstance<eCamSDK::Camera>(source_)) {
            auto* cam = source_.cast<eCamSDK::Camera*>();
            grab_ = [cam](Frame* f) { return static_cast<int>(cam->GetFrame(f)); };
        } else if (py::isinstance<NetStreamer::NetStreamingInfo>(source_)) {
            auto* net = source_.cast<NetStreamer::NetStreamingInfo*>();
            grab_ = [net](Frame* f) { return static_cast<int>(net->GetFrame(f)); };
        } else {
            throw py::type_error("FramePump source must be a Camera or NetStreamingInfo");
        }
    }
    ~FramePump() {
        // Python deallocates us with the GIL held, while the worker threads
        // may be waiting for the GIL inside a callback: join without it.
        if (Py_IsInitialized() && PyGILState_Check()) {
            py::gil_scoped_release nogil;
            stopAndJoin();
        } else {
            stopAndJoin();
        }
    }

    // ---- state shared with PreviewController (CameraContext fields) ------
    std::atomic<bool> isCrossStillCapture{false};
    std::atomic<bool> isSetImageProperty{false};
    std::atomic<bool> isBufferInitialized{false};
    std::atomic<int> width{0}, height{0}, stillWidth{0}, stillHeight{0}, pixValue{PF_NONE};
    std::mutex strMtx;
    std::string pixelValue, stillPixelValue;

    py::function onInitialized;  // (index)
    py::function onFrame;        // (index, capture_timestamp_ms)
    int index = 0;

    void start() {
        if (streaming_) return;
        streaming_ = true;
        grabThread_ = std::thread(&FramePump::grabLoop, this);
        processThread_ = std::thread(&FramePump::processLoop, this);
    }
    // Stop without joining (lets the caller call requestStop() on the network
    // stream in between, exactly like PreviewController::stopStream()).
    void signalStop() {
        streaming_ = false;
        { std::lock_guard<std::mutex> lock(queueMtx_); }
        queueCond_.notify_all();
        { std::lock_guard<std::mutex> lock(capture_->mtx); }
        capture_->notify();
    }
    void join() {
        if (grabThread_.joinable()) grabThread_.join();
        if (processThread_.joinable()) processThread_.join();
        {
            std::lock_guard<std::mutex> lock(queueMtx_);
            std::queue<Frame>().swap(queue_);
            std::queue<long long>().swap(timestamps_);
            spares_.clear();
        }
        std::lock_guard<std::mutex> lock(latencyMtx_);
        latency_.clear();
    }
    void stopAndJoin() { signalStop(); join(); }
    bool streaming() const { return streaming_; }

    // Still-capture support: blocks until a capture frame is ready, the
    // capture flag is cleared or streaming stops. Returns the frame or None.
    std::unique_ptr<Frame> waitCaptureFrame(double timeoutSec) {
        std::unique_lock<std::mutex> lock(capture_->mtx);
        const auto pred = [this] {
            return (capture_->value && captureReady_) || !streaming_;
        };
        if (timeoutSec < 0) capture_->cond.wait(lock, pred);
        else capture_->cond.wait_for(lock, std::chrono::duration<double>(timeoutSec), pred);
        if (!streaming_ || !capture_->value || !captureReady_) return nullptr;
        std::lock_guard<std::mutex> capLock(captureMtx_);
        auto out = std::make_unique<Frame>(captureFrame_);
        captureFrame_.rgb.frame_data.clear();
        captureReady_ = false;
        return out;
    }

    // PreviewController replaces its FBO list when QML creates the preview
    // items (updateFramebufferObject); the running pump follows the new slot.
    void setSlot(std::shared_ptr<FrameSlot> slot) {
        std::lock_guard<std::mutex> lock(slotMtx_);
        slot_ = std::move(slot);
    }
    std::shared_ptr<FrameSlot> getSlot() {
        std::lock_guard<std::mutex> lock(slotMtx_);
        return slot_;
    }

    // Capture-to-handoff latency samples, (capture epoch ms, latency ms), one
    // per displayed frame since the previous call. Bounded: the oldest are
    // dropped if nobody collects them.
    std::vector<std::pair<long long, long long>> takeLatencySamples() {
        std::vector<std::pair<long long, long long>> out;
        std::lock_guard<std::mutex> lock(latencyMtx_);
        out.swap(latency_);
        return out;
    }

    std::string getPixelValue() { std::lock_guard<std::mutex> l(strMtx); return pixelValue; }
    void setPixelValue(const std::string& v) { std::lock_guard<std::mutex> l(strMtx); pixelValue = v.substr(0, 7); }
    std::string getStillPixelValue() { std::lock_guard<std::mutex> l(strMtx); return stillPixelValue; }
    void setStillPixelValue(const std::string& v) { std::lock_guard<std::mutex> l(strMtx); stillPixelValue = v.substr(0, 7); }

  private:
    py::object source_;  // keeps the SDK object alive while threads run
    std::mutex slotMtx_;
    std::shared_ptr<FrameSlot> slot_;
    std::shared_ptr<CaptureFlag> capture_;
    bool network_;
    Grabber grab_;

    std::atomic<bool> streaming_{false};
    std::thread grabThread_, processThread_;
    std::mutex queueMtx_;
    std::condition_variable queueCond_;
    std::queue<Frame> queue_;
    std::queue<long long> timestamps_;
    Frame netFrame_{};   // CameraContext::wifiFrame (reused buffer)
    Frame current_{};    // CameraContext::frame
    std::vector<Frame> spares_;  // recycled USB frame buffers (guarded by queueMtx_)
    static constexpr size_t kMaxQueued = 5;
    static constexpr size_t kMaxSpares = kMaxQueued + 2;

    std::mutex latencyMtx_;
    std::vector<std::pair<long long, long long>> latency_;
    static constexpr size_t kMaxLatencySamples = 4096;

    std::mutex captureMtx_;
    Frame captureFrame_{};
    bool captureReady_ = false;

    // ---- grab thread (PreviewController::getFrame) ------------------------
    void grabLoop() {
        while (streaming_) {
            if (network_) grabNetwork(); else grabUsb();
        }
    }

    // Takes a recycled frame (its buffer already has the right capacity, so
    // the SDK's resize does not allocate) or a new one.
    Frame takeSpare() {
        std::lock_guard<std::mutex> lock(queueMtx_);
        if (spares_.empty()) return Frame{};
        Frame f = std::move(spares_.back());
        spares_.pop_back();
        return f;
    }
    // Caller holds queueMtx_.
    void recycleLocked(Frame&& f) {
        if (network_ || spares_.size() >= kMaxSpares) return;  // network frames are copies
        spares_.push_back(std::move(f));
    }
    void recycle(Frame&& f) {
        std::lock_guard<std::mutex> lock(queueMtx_);
        recycleLocked(std::move(f));
    }

    void grabUsb() {
        Frame temp = takeSpare();
        // V4L2::GetFrame (Linux) keeps returning Ok after it has moved the
        // newest frame out (it never pops it), leaving frame_data untouched.
        // A recycled buffer would then still hold an older frame and get shown
        // again out of order, so start empty and treat "still empty" as "no
        // new frame". Clearing keeps the capacity for the Windows SDK, which
        // resizes and memcpys into the buffer.
        temp.rgb.frame_data.clear();
        if (grab_(&temp) != 1) { recycle(std::move(temp)); return; }
        if (temp.rgb.frame_data.empty()) {
            recycle(std::move(temp));
            std::this_thread::sleep_for(std::chrono::milliseconds(1));  // don't spin on the SDK's mutex
            return;
        }
        if (isSetImageProperty) {
            std::string expectFmt;
            int ew, eh;
            if (isCrossStillCapture) {
                ew = stillWidth; eh = stillHeight; expectFmt = getStillPixelValue();
            } else {
                ew = width; eh = height; expectFmt = getPixelValue();
            }
            if (ew != temp.rgb.width || eh != temp.rgb.height ||
                std::strncmp(temp.rgb.pixel_format, expectFmt.c_str(), sizeof(temp.rgb.pixel_format)) != 0) {
                recycle(std::move(temp));
                return;  // stale frame from before the format switch
            }
            isSetImageProperty = false;
        }
        if (temp.rgb.total_size <= 0 || temp.rgb.frame_data.empty()) { recycle(std::move(temp)); return; }
        const long long ts = now_epoch_ms();
        {
            std::lock_guard<std::mutex> lock(queueMtx_);
            if (queue_.size() >= kMaxQueued) {
                recycleLocked(std::move(queue_.front()));
                queue_.pop();
                timestamps_.pop();
            }
            queue_.push(std::move(temp));
            timestamps_.push(ts);
        }
        queueCond_.notify_one();
    }

    void grabNetwork() {
        if (grab_(&netFrame_) != 1) return;
        if (netFrame_.rgb.total_size > 0 && !netFrame_.rgb.frame_data.empty()) {
            const long long ts = now_epoch_ms();
            {
                std::lock_guard<std::mutex> lock(queueMtx_);
                while (queue_.size() >= kMaxQueued) { queue_.pop(); timestamps_.pop(); }
                queue_.push(netFrame_);
                timestamps_.push(ts);
            }
            queueCond_.notify_one();
        }
    }

    // ---- process thread (processFrameThreadFunc / processFrames) ----------
    void processLoop() {
        while (streaming_) {
            long long ts = 0;
            {
                std::unique_lock<std::mutex> lock(queueMtx_);
                queueCond_.wait(lock, [this] { return !queue_.empty() || !streaming_; });
                if (!streaming_) break;
                current_ = std::move(queue_.front());
                queue_.pop();
                ts = timestamps_.front();
                timestamps_.pop();
            }
            processFrame(current_, ts);
            recycle(std::move(current_));
            current_ = Frame{};
        }
    }

    static bool sizeIs(const FrameBuffer& fb, double factor) {
        return static_cast<double>(fb.height) * fb.width * factor == static_cast<double>(fb.total_size);
    }

    // Pixel-format detection on the first frame of a stream (verbatim port).
    bool detectFormat(const FrameBuffer& fb, int& pix) {
        bool expected = false;
        const char* pf = fb.pixel_format;
        auto is = [pf](const char* s) { return std::strncmp(pf, s, 8) == 0; };
        if (is("UYVY")) {
            pix = UYVY; expected = sizeIs(fb, 2);
        } else if (is("YUYV") || is("YUY2")) {
            pix = YUYV; expected = sizeIs(fb, 2);
        } else if (is("MJPG")) {
            if (sizeIs(fb, 4)) { pix = RGB32; expected = true; }
            else if (sizeIs(fb, 2)) { pix = YUYV; expected = true; }
            else if (sizeIs(fb, 1.5)) { pix = NV12; expected = true; }
        } else if (is("NV12")) {
            pix = NV12;
            expected = static_cast<long long>(fb.height) * fb.width * 3 / 2 == fb.total_size;
        } else if (is("Y16")) {
            pix = Y16; expected = sizeIs(fb, 2);
        } else if (is("Y8")) {
            pix = Y8; expected = sizeIs(fb, 1);
        } else if (is("H264")) {
            if (sizeIs(fb, 4)) { pix = RGB32; expected = true; }
            if (sizeIs(fb, 1.5)) { pix = H264; expected = true; }
        } else if (is("HEVC") || is("H265")) {
            pix = HEVC; expected = sizeIs(fb, 1.5);
        } else if (is("MJPEG")) {
            pix = YUV420; expected = sizeIs(fb, 1.5);
        } else if (is("Y12")) {
            pix = Y12; expected = sizeIs(fb, 1.5);
        } else if (is("Y10")) {
            pix = Y10;
            expected = (static_cast<long long>(fb.height) * fb.width * 5) / 4 == fb.total_size;
        }
        return expected;
    }

    void processFrame(const Frame& frame, long long ts) {
        const std::shared_ptr<FrameSlot> slot = getSlot();
        if (!isBufferInitialized) {
            if (!slot->fboInitialized) return;
            int pix = pixValue;
            const bool expected = detectFormat(frame.rgb, pix);
            pixValue = pix;
            if (!(expected && frame.rgb.total_size != 0)) return;
            slot->initDrawBuffer(frame.rgb.total_size);
            slot->setData(frame.rgb.width, frame.rgb.height, pix);
            if (!isCrossStillCapture) {
                width = frame.rgb.width;
                height = frame.rgb.height;
                setPixelValue(std::string(frame.rgb.pixel_format, strnlen(frame.rgb.pixel_format, 8)));
                call(onInitialized, "FramePump.onInitialized", index);
            }
            isBufferInitialized = true;
        }
        if (!(isBufferInitialized && slot->fboInitialized)) return;

        if (capture_->value && !frame.rgb.frame_data.empty() && frame.rgb.total_size != 0) {
            {
                std::lock_guard<std::mutex> capLock(captureMtx_);
                captureFrame_ = frame;  // deep copy
                captureReady_ = true;
            }
            { std::lock_guard<std::mutex> lock(capture_->mtx); }
            capture_->notify();
        }
        if (!isCrossStillCapture) {
            slot->displayVideoFrame(frame.rgb.frame_data.data(), frame.rgb.total_size);
            {
                std::lock_guard<std::mutex> lock(latencyMtx_);
                if (latency_.size() >= kMaxLatencySamples) latency_.erase(latency_.begin());
                latency_.emplace_back(ts, now_epoch_ms() - ts);
            }
            call(onFrame, "FramePump.onFrame", index, ts);
        }
    }

    template <typename... Args>
    void call(py::function& fn, const char* where, Args... args) {
        if (!fn) return;
        py::gil_scoped_acquire gil;
        try {
            fn(args...);
        } catch (py::error_already_set& e) {
            e.restore();
            report_callback_error(where);
        }
    }
};

// Latest-frame hand-off for consumers that sample the stream (histogram).
class FrameTap {
  public:
    void push(const uint8_t* data, size_t size, int w, int h, int pix) {
        {
            std::lock_guard<std::mutex> lock(mtx_);
            if (buf_.size() != size) buf_.resize(size);
            std::memcpy(buf_.data(), data, size);
            w_ = w; h_ = h; pix_ = pix; fresh_ = true;
        }
        cond_.notify_one();
    }
    void close() {
        { std::lock_guard<std::mutex> lock(mtx_); closed_ = true; }
        cond_.notify_all();
    }
    // Returns (bytes, width, height, pixfmt) or None on timeout/close.
    py::object wait(double timeoutSec) {
        std::vector<uint8_t> out;
        int w = 0, h = 0, pix = 0;
        {
            py::gil_scoped_release nogil;
            std::unique_lock<std::mutex> lock(mtx_);
            cond_.wait_for(lock, std::chrono::duration<double>(timeoutSec), [this] { return fresh_ || closed_; });
            if (!fresh_ || closed_) return py::object(py::none());
            out.swap(buf_);
            w = w_; h = h_; pix = pix_;
            fresh_ = false;
        }
        return py::make_tuple(py::bytes(reinterpret_cast<const char*>(out.data()), out.size()), w, h, pix);
    }

  private:
    std::mutex mtx_;
    std::condition_variable cond_;
    std::vector<uint8_t> buf_;
    int w_ = 0, h_ = 0, pix_ = 0;
    bool fresh_ = false, closed_ = false;
};

void bind_frame_pump(py::module_& m) {
    py::module_ pf = m.def_submodule("Pixelformat", "Pixel format codes (OpenGlDisplay.h)");
#define TS_PF(name) pf.attr(#name) = static_cast<int>(name)
    TS_PF(UYVY); TS_PF(Y16); TS_PF(RGB32); TS_PF(YUYV); TS_PF(Y8); TS_PF(MJPG); TS_PF(Y12);
    TS_PF(BY8); TS_PF(BY10); TS_PF(BY12); TS_PF(H264); TS_PF(YUV420); TS_PF(HEVC); TS_PF(BY16);
    TS_PF(NV12); TS_PF(Y10);
#undef TS_PF

    py::class_<FrameSlot, std::shared_ptr<FrameSlot>>(m, "FrameSlot", py::buffer_protocol())
        .def(py::init<>())
        .def("initDrawBuffer", &FrameSlot::initDrawBuffer, py::call_guard<py::gil_scoped_release>())
        .def("setData", &FrameSlot::setData, py::call_guard<py::gil_scoped_release>())
        .def("displayVideoFrame",
             [](FrameSlot& s, py::buffer data) {
                 py::buffer_info info = data.request();
                 const auto* ptr = static_cast<const uint8_t*>(info.ptr);
                 const size_t size = static_cast<size_t>(info.size * info.itemsize);
                 py::gil_scoped_release nogil;
                 return s.displayVideoFrame(ptr, size);
             })
        .def("stopFrame", &FrameSlot::stopFrame, py::call_guard<py::gil_scoped_release>())
        .def("cleanOpenGLDisplay", &FrameSlot::clean, py::call_guard<py::gil_scoped_release>())
        .def_property("fboInitialized",
                      [](const FrameSlot& s) { return s.fboInitialized.load(); },
                      [](FrameSlot& s, bool v) { s.fboInitialized = v; })
        .def_property_readonly("framesWritten", [](const FrameSlot& s) { return s.framesWritten.load(); })
        // Render-thread access: lock() ... read state / buffer ... unlock().
        .def("lock", [](FrameSlot& s) { py::gil_scoped_release nogil; s.mtx.lock(); })
        .def("unlock", [](FrameSlot& s) { s.mtx.unlock(); })
        .def("take_reset", [](FrameSlot& s) { const bool r = s.needsReset; s.needsReset = false; return r; },
             "Caller must hold lock(). True once after the buffer was re-initialised.")
        .def_property_readonly("gotFrame", [](const FrameSlot& s) { return s.gotFrame; })
        .def_property_readonly("width", [](const FrameSlot& s) { return s.width; })
        .def_property_readonly("height", [](const FrameSlot& s) { return s.height; })
        .def_property_readonly("pixfmt", [](const FrameSlot& s) { return s.pixfmt; })
        .def_property_readonly("size", [](const FrameSlot& s) { return s.buf.size(); })
        .def_buffer([](FrameSlot& s) -> py::buffer_info {
            return py::buffer_info(s.buf.data(), 1, py::format_descriptor<uint8_t>::format(), 1,
                                   {static_cast<py::ssize_t>(s.buf.size())}, {1});
        });

    py::class_<CaptureFlag, std::shared_ptr<CaptureFlag>>(m, "CaptureFlag")
        .def(py::init<>())
        .def("set", &CaptureFlag::set, py::call_guard<py::gil_scoped_release>())
        .def("get", [](const CaptureFlag& c) { return c.value.load(); })
        .def("notify", &CaptureFlag::notify);

    py::class_<FrameTap, std::shared_ptr<FrameTap>>(m, "FrameTap")
        .def(py::init<>())
        .def("push",
             [](FrameTap& t, py::buffer data, int w, int h, int pix) {
                 py::buffer_info info = data.request();
                 const auto* ptr = static_cast<const uint8_t*>(info.ptr);
                 const size_t size = static_cast<size_t>(info.size * info.itemsize);
                 py::gil_scoped_release nogil;
                 t.push(ptr, size, w, h, pix);
             })
        .def("push_slot",
             [](FrameTap& t, FrameSlot& s) {
                 py::gil_scoped_release nogil;
                 std::lock_guard<std::mutex> lock(s.mtx);
                 if (s.gotFrame && !s.buf.empty()) t.push(s.buf.data(), s.buf.size(), s.width, s.height, s.pixfmt);
             },
             "Copy the slot's current frame into the tap.")
        .def("wait", &FrameTap::wait, py::arg("timeout") = 0.5)
        .def("close", &FrameTap::close);

    py::class_<FramePump>(m, "FramePump")
        .def(py::init<py::object, std::shared_ptr<FrameSlot>, std::shared_ptr<CaptureFlag>, bool>(),
             py::arg("source"), py::arg("slot"), py::arg("capture"), py::arg("network"))
        .def("start", &FramePump::start, py::call_guard<py::gil_scoped_release>())
        .def("signalStop", &FramePump::signalStop, py::call_guard<py::gil_scoped_release>())
        .def("join", &FramePump::join, py::call_guard<py::gil_scoped_release>())
        .def("stop", &FramePump::stopAndJoin, py::call_guard<py::gil_scoped_release>())
        .def_property_readonly("streaming", &FramePump::streaming)
        .def("waitCaptureFrame",
             [](FramePump& p, double timeout) -> py::object {
                 std::unique_ptr<Frame> f;
                 {
                     py::gil_scoped_release nogil;
                     f = p.waitCaptureFrame(timeout);
                 }
                 if (!f) return py::none();
                 return py::cast(std::move(f));
             },
             py::arg("timeout") = -1.0)
        .def_property("slot", &FramePump::getSlot, &FramePump::setSlot)
        .def_readwrite("index", &FramePump::index)
        .def_readwrite("onInitialized", &FramePump::onInitialized)
        .def_readwrite("onFrame", &FramePump::onFrame)
        .def("takeLatencySamples", &FramePump::takeLatencySamples,
             py::call_guard<py::gil_scoped_release>(),
             "[(capture_epoch_ms, latency_ms), ...] since the previous call.")
#define TS_ATOMIC(name, T)                                                           \
    .def_property(#name, [](const FramePump& p) { return p.name.load(); },           \
                  [](FramePump& p, T v) { p.name = v; })
        TS_ATOMIC(isCrossStillCapture, bool)
        TS_ATOMIC(isSetImageProperty, bool)
        TS_ATOMIC(isBufferInitialized, bool)
        TS_ATOMIC(width, int)
        TS_ATOMIC(height, int)
        TS_ATOMIC(stillWidth, int)
        TS_ATOMIC(stillHeight, int)
        TS_ATOMIC(pixValue, int)
#undef TS_ATOMIC
        .def_property("pixelValue", &FramePump::getPixelValue, &FramePump::setPixelValue)
        .def_property("stillPixelValue", &FramePump::getStillPixelValue, &FramePump::setStillPixelValue);
}
