// Still-image conversion and encoding (verbatim ports from
// CamVistra/Controller/src/PreviewController.cpp so saved files are
// byte-identical to the C++ application):
//   yuv420ToRgb / nv12ToRgb / rgb32ToRgb24 / uyvyToRgb / yuyvToRgb / y8ToRgb / y12ToRgb
//   saveBMP / savePNG (stored-deflate PngWriter) / saveJPEG (turbojpeg) / saveRAW
// All functions take buffer-protocol objects and run without the GIL.
#include "common.h"

#include <array>
#include <cstdio>
#include <fstream>

#include <turbojpeg.h>

namespace {

inline uint8_t clampToByte(int value) {
    if (value < 0) return 0;
    if (value > 255) return 255;
    return static_cast<uint8_t>(value);
}

struct View {
    const uint8_t* ptr;
    size_t size;
};

View view_of(const py::buffer& b) {
    py::buffer_info info = b.request();
    return {static_cast<const uint8_t*>(info.ptr), static_cast<size_t>(info.size * info.itemsize)};
}

bool yuv420ToRgb(const uint8_t* yuv420p, int width, int height, uint8_t* rgbBuffer) {
    if (yuv420p == nullptr) return false;
    const int frameSize = width * height;
    const int chromaSize = frameSize / 4;
    const uint8_t* yPlane = yuv420p;
    const uint8_t* uPlane = yuv420p + frameSize;
    const uint8_t* vPlane = yuv420p + frameSize + chromaSize;
    for (int j = 0; j < height; ++j) {
        for (int i = 0; i < width; ++i) {
            const int yIndex = (j * width) + i;
            const int uvIndex = ((j / 2) * (width / 2)) + (i / 2);
            const int scaledY = yPlane[yIndex] - 16;
            const int scaledU = uPlane[uvIndex] - 128;
            const int scaledV = vPlane[uvIndex] - 128;
            int r = (298 * scaledY + 516 * scaledU + 128) >> 8;
            int g = (298 * scaledY - 100 * scaledU - 208 * scaledV + 128) >> 8;
            int b = (298 * scaledY + 409 * scaledV + 128) >> 8;
            const int rgbIndex = yIndex * 3;
            rgbBuffer[rgbIndex + 0] = clampToByte(r);
            rgbBuffer[rgbIndex + 1] = clampToByte(g);
            rgbBuffer[rgbIndex + 2] = clampToByte(b);
        }
    }
    return true;
}

bool nv12ToRgb(const uint8_t* nv12, int width, int height, uint8_t* rgbBuffer) {
    if (nv12 == nullptr || rgbBuffer == nullptr || width <= 0 || height <= 0) return false;
    const uint8_t* yPlane = nv12;
    const uint8_t* uvPlane = nv12 + (width * height);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            const int yValue = yPlane[(y * width) + x];
            const int uvIndex = ((y / 2) * width) + (x & ~1);
            const int uValue = static_cast<int>(uvPlane[uvIndex]) - 128;
            const int vValue = static_cast<int>(uvPlane[uvIndex + 1]) - 128;
            const int rgbIndex = ((y * width) + x) * 3;
            rgbBuffer[rgbIndex] = clampToByte(static_cast<int>(yValue + (1.402f * vValue)));
            rgbBuffer[rgbIndex + 1] = clampToByte(static_cast<int>(yValue - (0.344f * uValue) - (0.714f * vValue)));
            rgbBuffer[rgbIndex + 2] = clampToByte(static_cast<int>(yValue + (1.772f * uValue)));
        }
    }
    return true;
}

bool rgb32ToRgb24(const uint8_t* rgb32, int width, int height, uint8_t* rgb24) {
    if (rgb32 == nullptr || rgb24 == nullptr || width <= 0 || height <= 0) return false;
    const size_t pixelCount = static_cast<size_t>(width) * static_cast<size_t>(height);
    for (size_t i = 0; i < pixelCount; i++) {
        rgb24[(i * 3) + 2] = rgb32[(i * 4) + 0];
        rgb24[(i * 3) + 1] = rgb32[(i * 4) + 1];
        rgb24[(i * 3) + 0] = rgb32[(i * 4) + 2];
    }
    return true;
}

bool uyvyToRgb(const uint8_t* uyvy, int width, int height, uint8_t* rgb) {
    if (uyvy == nullptr || rgb == nullptr) return false;
    int out = 0;
    const int byteCount = width * height * 2;
    for (int index = 0; index < byteCount; index += 4) {
        const int u = static_cast<int>(uyvy[index + 0]) - 128;
        const int y0 = static_cast<int>(uyvy[index + 1]) - 16;
        const int v = static_cast<int>(uyvy[index + 2]) - 128;
        const int y1 = static_cast<int>(uyvy[index + 3]) - 16;
        rgb[out++] = clampToByte((298 * y0 + 516 * u + 128) >> 8);
        rgb[out++] = clampToByte((298 * y0 - 100 * u - 208 * v + 128) >> 8);
        rgb[out++] = clampToByte((298 * y0 + 409 * v + 128) >> 8);
        rgb[out++] = clampToByte((298 * y1 + 516 * u + 128) >> 8);
        rgb[out++] = clampToByte((298 * y1 - 100 * u - 208 * v + 128) >> 8);
        rgb[out++] = clampToByte((298 * y1 + 409 * v + 128) >> 8);
    }
    return true;
}

bool yuyvToRgb(const uint8_t* yuyv, int width, int height, uint8_t* rgb) {
    if (yuyv == nullptr || rgb == nullptr || width <= 0 || height <= 0) return false;
    const int totalPixels = width * height;
    const uint8_t* src = yuyv;
    uint8_t* dst = rgb;
    for (int p = 0; p < totalPixels; p += 2) {
        const int y0 = src[0];
        const int u = static_cast<int>(src[1]) - 128;
        const int y1 = src[2];
        const int v = static_cast<int>(src[3]) - 128;
        src += 4;
        dst[0] = clampToByte(static_cast<int>(y0 + (1.772 * u)));
        dst[1] = clampToByte(static_cast<int>(y0 - (0.344 * u) - (0.714 * v)));
        dst[2] = clampToByte(static_cast<int>(y0 + (1.402 * v)));
        dst += 3;
        dst[0] = clampToByte(static_cast<int>(y1 + (1.772 * u)));
        dst[1] = clampToByte(static_cast<int>(y1 - (0.344 * u) - (0.714 * v)));
        dst[2] = clampToByte(static_cast<int>(y1 + (1.402 * v)));
        dst += 3;
    }
    return true;
}

// Packed Y12: two pixels in three bytes, [P0 hi8][P1 hi8][P1 lo4 | P0 lo4]; keeps the high 8 bits.
bool y12ToRgb(const uint8_t* y12, int width, int height, uint8_t* rgb) {
    if (y12 == nullptr || rgb == nullptr || width <= 0 || height <= 0) return false;
    const size_t totalPixels = static_cast<size_t>(width) * static_cast<size_t>(height);
    for (size_t p = 0; p + 1 < totalPixels; p += 2) {
        rgb[0] = rgb[1] = rgb[2] = y12[0];
        rgb[3] = rgb[4] = rgb[5] = y12[1];
        y12 += 3;
        rgb += 6;
    }
    return true;
}

bool y8ToRgb(const uint8_t* y8, int width, int height, uint8_t* rgb) {
    if (y8 == nullptr || rgb == nullptr || width <= 0 || height <= 0) return false;
    const size_t totalPixels = static_cast<size_t>(width) * static_cast<size_t>(height);
    for (size_t p = 0; p < totalPixels; ++p) {
        rgb[0] = rgb[1] = rgb[2] = y8[p];
        rgb += 3;
    }
    return true;
}

#pragma pack(push, 1)
struct BmpFileHeader {
    uint16_t bfType = 0; uint32_t bfSize = 0; uint16_t bfReserved1 = 0; uint16_t bfReserved2 = 0;
    uint32_t bfOffBits = 0;
};
struct BmpInfoHeader {
    uint32_t biSize = 0; int32_t biWidth = 0; int32_t biHeight = 0; uint16_t biPlanes = 0;
    uint16_t biBitCount = 0; uint32_t biCompression = 0; uint32_t biSizeImage = 0;
    int32_t biXPelsPerMeter = 0; int32_t biYPelsPerMeter = 0; uint32_t biClrUsed = 0;
    uint32_t biClrImportant = 0;
};
#pragma pack(pop)

// The C++ PreviewController keeps its BMP headers as members, so values from
// a previous save persist; only the fields below are ever set, and the rest
// stay zero-initialised - reproduced here with fresh zeroed headers.
bool saveBMP(const std::string& filename, const uint8_t* rgb, int width, int height) {
    const int rowSize = width * 3;
    const int paddingSize = (4 - (rowSize % 4)) % 4;
    const int imageDataSize = (rowSize + paddingSize) * height;
    BmpFileHeader fh{};
    BmpInfoHeader ih{};
    fh.bfType = 0x4D42;
    fh.bfSize = 54 + imageDataSize;
    fh.bfOffBits = 54;
    ih.biSize = 40; ih.biWidth = width; ih.biHeight = height; ih.biPlanes = 1;
    ih.biBitCount = 24; ih.biCompression = 0; ih.biSizeImage = imageDataSize;
    std::ofstream out(filename, std::ios::binary);
    if (!out) return false;
    out.write(reinterpret_cast<const char*>(&fh), sizeof(fh));
    out.write(reinterpret_cast<const char*>(&ih), sizeof(ih));
    for (int row = height - 1; row >= 0; --row) {
        out.write(reinterpret_cast<const char*>(&rgb[static_cast<size_t>(row) * width * 3]), rowSize);
        out.write("\0\0\0", paddingSize);
    }
    return static_cast<bool>(out);
}

uint32_t crc32Update(uint32_t crc, const uint8_t* data, size_t len) {
    static const auto table = [] {
        std::array<uint32_t, 256> t{};
        for (uint32_t i = 0; i < 256; ++i) {
            uint32_t c = i;
            for (int k = 0; k < 8; ++k) c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
            t[i] = c;
        }
        return t;
    }();
    for (size_t i = 0; i < len; ++i) crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8);
    return crc;
}

uint32_t adler32(const uint8_t* data, size_t len) {
    uint32_t s1 = 1, s2 = 0;
    for (size_t i = 0; i < len; ++i) {
        s1 = (s1 + data[i]) % 65521;
        s2 = (s2 + s1) % 65521;
    }
    return (s2 << 16) | s1;
}

// Minimal PNG writer (stored/uncompressed deflate blocks), input BGR24.
struct PngWriter {
    std::vector<uint8_t> buf;
    void u32be(uint32_t v) {
        buf.push_back((v >> 24) & 0xFF); buf.push_back((v >> 16) & 0xFF);
        buf.push_back((v >> 8) & 0xFF); buf.push_back(v & 0xFF);
    }
    void chunk(const char type[4], const uint8_t* data, uint32_t len) {
        u32be(len);
        const size_t crcStart = buf.size();
        buf.insert(buf.end(), type, type + 4);
        if (len) buf.insert(buf.end(), data, data + len);
        u32be(crc32Update(0xFFFFFFFFu, buf.data() + crcStart, 4 + len) ^ 0xFFFFFFFFu);
    }
    void build(const uint8_t* bgr, int width, int height) {
        const uint8_t sig[8] = {137, 80, 78, 71, 13, 10, 26, 10};
        buf.insert(buf.end(), sig, sig + 8);
        uint8_t ihdr[13];
        auto w32 = [](uint8_t* b, uint32_t v) {
            b[0] = (v >> 24) & 0xFF; b[1] = (v >> 16) & 0xFF; b[2] = (v >> 8) & 0xFF; b[3] = v & 0xFF;
        };
        w32(ihdr, static_cast<uint32_t>(width));
        w32(ihdr + 4, static_cast<uint32_t>(height));
        ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
        chunk("IHDR", ihdr, 13);

        const int rowBytes = 1 + width * 3;
        std::vector<uint8_t> raw(static_cast<size_t>(rowBytes) * height);
        for (int y = 0; y < height; ++y) {
            raw[static_cast<size_t>(y) * rowBytes] = 0x00;
            const uint8_t* src = bgr + static_cast<size_t>(y) * width * 3;
            uint8_t* dst = raw.data() + static_cast<size_t>(y) * rowBytes + 1;
            for (int x = 0; x < width; ++x, src += 3, dst += 3) {
                dst[0] = src[2]; dst[1] = src[1]; dst[2] = src[0];
            }
        }
        const size_t rawLen = raw.size();
        const uint16_t MAXBLK = 65535;
        std::vector<uint8_t> deflate{0x78, 0x01};
        size_t pos = 0;
        while (pos < rawLen) {
            const size_t remain = rawLen - pos;
            const uint16_t blen = static_cast<uint16_t>(remain > MAXBLK ? MAXBLK : remain);
            const bool last = (pos + blen >= rawLen);
            deflate.push_back(last ? 0x01 : 0x00);
            deflate.push_back(blen & 0xFF);
            deflate.push_back((blen >> 8) & 0xFF);
            deflate.push_back(~blen & 0xFF);
            deflate.push_back((~blen >> 8) & 0xFF);
            deflate.insert(deflate.end(), raw.begin() + pos, raw.begin() + pos + blen);
            pos += blen;
        }
        const uint32_t a32 = adler32(raw.data(), rawLen);
        deflate.push_back((a32 >> 24) & 0xFF); deflate.push_back((a32 >> 16) & 0xFF);
        deflate.push_back((a32 >> 8) & 0xFF); deflate.push_back(a32 & 0xFF);
        chunk("IDAT", deflate.data(), static_cast<uint32_t>(deflate.size()));
        chunk("IEND", nullptr, 0);
    }
};

bool writeFile(const std::string& filename, const uint8_t* data, size_t size) {
    FILE* f = nullptr;
#ifdef _WIN32
    fopen_s(&f, filename.c_str(), "wb");
#else
    f = fopen(filename.c_str(), "wb");
#endif
    if (f == nullptr) return false;
    const size_t written = fwrite(data, 1, size, f);
    fclose(f);
    return written == size;
}

bool savePNG(const std::string& filename, const uint8_t* bgr, int width, int height) {
    if (bgr == nullptr || width <= 0 || height <= 0) return false;
    PngWriter pw;
    pw.build(bgr, width, height);
    return writeFile(filename, pw.buf.data(), pw.buf.size());
}

bool saveJPEG(const std::string& filename, const uint8_t* bgr, int width, int height, std::string& error) {
    if (bgr == nullptr || width <= 0 || height <= 0) { error = "JPEG input is invalid"; return false; }
    tjhandle handle = tjInitCompress();
    if (handle == nullptr) { error = "JPEG compressor initialization failed"; return false; }
    unsigned char* jpegBuf = nullptr;
    unsigned long jpegSize = 0;
    const int ret = tjCompress2(handle, bgr, width, 0, height, TJPF_BGR, &jpegBuf, &jpegSize,
                                TJSAMP_420, 90, 0);
    if (ret != 0) {
        tjDestroy(handle);
        error = "JPEG compression failed";
        return false;
    }
    const bool ok = writeFile(filename, jpegBuf, jpegSize);
    if (!ok) error = "JPEG file could not be written";
    tjFree(jpegBuf);
    tjDestroy(handle);
    return ok;
}

using Converter = bool (*)(const uint8_t*, int, int, uint8_t*);

py::object convert(Converter fn, const py::buffer& src, int width, int height) {
    const View v = view_of(src);
    if (width <= 0 || height <= 0) return py::none();
    std::string out(static_cast<size_t>(width) * static_cast<size_t>(height) * 3, '\0');
    bool ok;
    {
        py::gil_scoped_release nogil;
        ok = fn(v.ptr, width, height, reinterpret_cast<uint8_t*>(&out[0]));
    }
    if (!ok) return py::none();
    return py::bytes(out);
}

}  // namespace

void bind_imaging(py::module_& m) {
    py::module_ im = m.def_submodule("imaging", "Still-image conversion/encoding (PreviewController.cpp)");
    im.def("yuv420ToRgb", [](py::buffer b, int w, int h) { return convert(yuv420ToRgb, b, w, h); });
    im.def("nv12ToRgb", [](py::buffer b, int w, int h) { return convert(nv12ToRgb, b, w, h); });
    im.def("rgb32ToRgb24", [](py::buffer b, int w, int h) { return convert(rgb32ToRgb24, b, w, h); });
    im.def("uyvyToRgb", [](py::buffer b, int w, int h) { return convert(uyvyToRgb, b, w, h); });
    im.def("yuyvToRgb", [](py::buffer b, int w, int h) { return convert(yuyvToRgb, b, w, h); });
    im.def("y8ToRgb", [](py::buffer b, int w, int h) { return convert(y8ToRgb, b, w, h); });
    im.def("y12ToRgb", [](py::buffer b, int w, int h) { return convert(y12ToRgb, b, w, h); });

    im.def("saveBMP", [](const std::string& path, py::buffer rgb, int w, int h) {
        const View v = view_of(rgb);
        if (v.size < static_cast<size_t>(w) * h * 3) return false;
        py::gil_scoped_release nogil;
        return saveBMP(path, v.ptr, w, h);
    });
    im.def("savePNG", [](const std::string& path, py::buffer bgr, int w, int h) {
        const View v = view_of(bgr);
        if (v.size < static_cast<size_t>(w) * h * 3) return false;
        py::gil_scoped_release nogil;
        return savePNG(path, v.ptr, w, h);
    });
    im.def("saveJPEG", [](const std::string& path, py::buffer bgr, int w, int h) {
        const View v = view_of(bgr);
        std::string error;
        bool ok = false;
        if (v.size >= static_cast<size_t>(w) * h * 3) {
            py::gil_scoped_release nogil;
            ok = saveJPEG(path, v.ptr, w, h, error);
        } else {
            error = "JPEG input is invalid";
        }
        return py::make_tuple(ok, error);
    });
    im.def("saveRAW", [](const std::string& path, py::buffer data) {
        const View v = view_of(data);
        py::gil_scoped_release nogil;
        return writeFile(path, v.ptr, v.size);
    });
}
