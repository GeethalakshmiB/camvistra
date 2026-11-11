// Frame / FrameBuffer (Logger/Common_Structs.h).
//
// A Frame is filled in place by Camera.GetFrame / NetStreamingInfo.GetFrame.
// FrameBuffer exposes its pixel bytes through the buffer protocol, so
// numpy.frombuffer(frame.rgb, ...) or memoryview(frame.rgb) is zero-copy.
// The view is only valid until the Frame is filled again.
#include "common.h"

void bind_frames(py::module_& m) {
    py::class_<FrameBuffer>(m, "FrameBuffer", py::buffer_protocol())
        .def(py::init<>())
        .def_readwrite("width", &FrameBuffer::width)
        .def_readwrite("height", &FrameBuffer::height)
        .def_readwrite("total_size", &FrameBuffer::total_size)
        .def_property(
            "pixel_format",
            [](const FrameBuffer& fb) { return ts::to_py(fb.pixel_format); },
            [](FrameBuffer& fb, py::handle v) { ts::from_py(v, fb.pixel_format); })
        .def_property_readonly("size", [](const FrameBuffer& fb) { return fb.frame_data.size(); })
        .def("tobytes",
             [](const FrameBuffer& fb) {
                 return py::bytes(reinterpret_cast<const char*>(fb.frame_data.data()), fb.frame_data.size());
             })
        .def("clear", [](FrameBuffer& fb) { fb.frame_data.clear(); })
        .def_buffer([](FrameBuffer& fb) -> py::buffer_info {
            return py::buffer_info(fb.frame_data.data(), 1, py::format_descriptor<uint8_t>::format(), 1,
                                   {static_cast<py::ssize_t>(fb.frame_data.size())}, {1});
        });

    py::class_<Frame>(m, "Frame")
        .def(py::init([]() {
            auto f = std::make_unique<Frame>();
            std::memset(f->rgb.pixel_format, 0, sizeof(f->rgb.pixel_format));
            std::memset(f->ir.pixel_format, 0, sizeof(f->ir.pixel_format));
            f->rgb.total_size = f->ir.total_size = 0;
            return f;
        }))
        .def_readonly("rgb", &Frame::rgb, py::return_value_policy::reference_internal)
        .def_readonly("ir", &Frame::ir, py::return_value_policy::reference_internal)
        .def("copy_from", [](Frame& self, const Frame& other) { self = other; }, py::arg("other"),
             py::call_guard<py::gil_scoped_release>());
}
