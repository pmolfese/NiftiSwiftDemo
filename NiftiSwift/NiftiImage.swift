import Foundation

// Make sure nifti1_io.h and the nifti_clib library are properly bridged for Swift.

class NiftiImage {
    private var niftiPtr: UnsafeMutablePointer<nifti_image>?
    let filename: String

    /// Loads a NIFTI file at the given path. Returns nil if loading fails.
    init?(filename: String) {
        self.filename = filename
        guard let img = nifti_image_read(filename, 1) else {
            print("Failed to load NIFTI file: \(filename)")
            return nil
        }
        self.niftiPtr = img
    }

    deinit {
        if let img = niftiPtr {
            nifti_image_free(img)
        }
    }

    /// NIFTI image dimensions as an array (up to 7D). For most images: [x, y, z].
    var dimensions: [Int] {
        guard let img = niftiPtr else { return [] }
        let ndim = Int(img.pointee.dim.0)
        let dim = img.pointee.dim
        let dimArray = [dim.1, dim.2, dim.3, dim.4, dim.5, dim.6, dim.7]
        return Array(dimArray.prefix(ndim)).map { Int($0) }
    }

    /// Voxel spacing for each dimension (from pixdim array).
    var spacing: [Float] {
        guard let img = niftiPtr else { return [] }
        let pixdim = img.pointee.pixdim
        return [pixdim.1, pixdim.2, pixdim.3, pixdim.4, pixdim.5, pixdim.6, pixdim.7]
            .prefix(dimensions.count)
            .map { Float($0) }
    }

    /// NIFTI datatype (DT_FLOAT32, DT_INT16, etc.)
    var dataType: Int32 {
        guard let img = niftiPtr else { return 0 }
        return img.pointee.datatype
    }

    /// Returns a human-readable datatype string
    var dataTypeDescription: String {
        switch dataType {
        case DT_UINT8: return "uint8"
        case DT_INT16: return "int16"
        case DT_INT32: return "int32"
        case DT_FLOAT32: return "float32"
        case DT_FLOAT64: return "float64"
        default: return "unknown"
        }
    }

    /// Get a Z slice (XY plane) at index z. Returns a [Float]? of size x*y.
    func sliceZ(_ z: Int) -> [Float]? {
        guard let img = niftiPtr else { return nil }
        let (nx, ny, nz) = (Int(img.pointee.dim.1), Int(img.pointee.dim.2), Int(img.pointee.dim.3))
        guard nx > 0, ny > 0, nz > 0, z >= 0, z < nz else { return nil }
        guard let data = img.pointee.data else { return nil }
        let dtype = img.pointee.datatype
        let offset = z * nx * ny

        switch dtype {
        case DT_UINT8:
            return extractSliceUInt8(pointer: data, count: nx*ny, at: offset)
        case DT_INT16:
            return extractSliceInt16(pointer: data, count: nx*ny, at: offset)
        case DT_INT32:
            return extractSliceInt32(pointer: data, count: nx*ny, at: offset)
        case DT_FLOAT32:
            return extractSliceFloat32(pointer: data, count: nx*ny, at: offset)
        case DT_FLOAT64:
            return extractSliceFloat64(pointer: data, count: nx*ny, at: offset)
        default:
            print("Unsupported data type: \(dtype)")
            return nil
        }
    }

    /// Get a Y slice (XZ plane) at index y. Returns a [Float]? of size x*z.
    func sliceY(_ y: Int) -> [Float]? {
        guard let img = niftiPtr else { return nil }
        let (nx, ny, nz) = (Int(img.pointee.dim.1), Int(img.pointee.dim.2), Int(img.pointee.dim.3))
        guard nx > 0, ny > 0, nz > 0, y >= 0, y < ny else { return nil }
        guard let data = img.pointee.data else { return nil }
        let dtype = img.pointee.datatype

        switch dtype {
        case DT_UINT8:
            return sliceY_Generic(pointer: data, nx: nx, ny: ny, nz: nz, y: y, type: UInt8.self)
        case DT_INT16:
            return sliceY_Generic(pointer: data, nx: nx, ny: ny, nz: nz, y: y, type: Int16.self)
        case DT_INT32:
            return sliceY_Generic(pointer: data, nx: nx, ny: ny, nz: nz, y: y, type: Int32.self)
        case DT_FLOAT32:
            return sliceY_Generic(pointer: data, nx: nx, ny: ny, nz: nz, y: y, type: Float.self)
        case DT_FLOAT64:
            return sliceY_Generic(pointer: data, nx: nx, ny: ny, nz: nz, y: y, type: Double.self)
        default:
            print("Unsupported data type: \(dtype)")
            return nil
        }
    }

    /// Get an X slice (YZ plane) at index x. Returns a [Float]? of size y*z.
    func sliceX(_ x: Int) -> [Float]? {
        guard let img = niftiPtr else { return nil }
        let (nx, ny, nz) = (Int(img.pointee.dim.1), Int(img.pointee.dim.2), Int(img.pointee.dim.3))
        guard nx > 0, ny > 0, nz > 0, x >= 0, x < nx else { return nil }
        guard let data = img.pointee.data else { return nil }
        let dtype = img.pointee.datatype

        switch dtype {
        case DT_UINT8:
            return sliceX_Generic(pointer: data, nx: nx, ny: ny, nz: nz, x: x, type: UInt8.self)
        case DT_INT16:
            return sliceX_Generic(pointer: data, nx: nx, ny: ny, nz: nz, x: x, type: Int16.self)
        case DT_INT32:
            return sliceX_Generic(pointer: data, nx: nx, ny: ny, nz: nz, x: x, type: Int32.self)
        case DT_FLOAT32:
            return sliceX_Generic(pointer: data, nx: nx, ny: ny, nz: nz, x: x, type: Float.self)
        case DT_FLOAT64:
            return sliceX_Generic(pointer: data, nx: nx, ny: ny, nz: nz, x: x, type: Double.self)
        default:
            print("Unsupported data type: \(dtype)")
            return nil
        }
    }

    // --- Helper extraction functions ---

    private func extractSliceUInt8(pointer: UnsafeRawPointer, count: Int, at offset: Int = 0) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: UInt8.self).advanced(by: offset)
        let buffer = UnsafeBufferPointer(start: typedPointer, count: count)
        return buffer.map { Float($0) }
    }
    private func extractSliceInt16(pointer: UnsafeRawPointer, count: Int, at offset: Int = 0) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: Int16.self).advanced(by: offset)
        let buffer = UnsafeBufferPointer(start: typedPointer, count: count)
        return buffer.map { Float($0) }
    }
    private func extractSliceInt32(pointer: UnsafeRawPointer, count: Int, at offset: Int = 0) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: Int32.self).advanced(by: offset)
        let buffer = UnsafeBufferPointer(start: typedPointer, count: count)
        return buffer.map { Float($0) }
    }
    private func extractSliceFloat32(pointer: UnsafeRawPointer, count: Int, at offset: Int = 0) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: Float.self).advanced(by: offset)
        let buffer = UnsafeBufferPointer(start: typedPointer, count: count)
        return Array(buffer)
    }
    private func extractSliceFloat64(pointer: UnsafeRawPointer, count: Int, at offset: Int = 0) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: Double.self).advanced(by: offset)
        let buffer = UnsafeBufferPointer(start: typedPointer, count: count)
        return buffer.map { Float($0) }
    }

    // Generic Y slice for any type
    private func sliceY_Generic<T>(pointer: UnsafeRawPointer, nx: Int, ny: Int, nz: Int, y: Int, type: T.Type) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: T.self)
        var slice = [Float](repeating: 0, count: nx * nz)
        for z in 0..<nz {
            let base = z * nx * ny
            for x in 0..<nx {
                let val = typedPointer[base + y * nx + x]
                slice[z * nx + x] = floatCast(val)
            }
        }
        return slice
    }
    // Generic X slice for any type
    private func sliceX_Generic<T>(pointer: UnsafeRawPointer, nx: Int, ny: Int, nz: Int, x: Int, type: T.Type) -> [Float] {
        let typedPointer = pointer.assumingMemoryBound(to: T.self)
        var slice = [Float](repeating: 0, count: ny * nz)
        for z in 0..<nz {
            let base = z * nx * ny
            for y in 0..<ny {
                let val = typedPointer[base + y * nx + x]
                slice[z * ny + y] = floatCast(val)
            }
        }
        return slice
    }

    // Helper to cast to Float
    private func floatCast<T>(_ val: T) -> Float {
        if let v = val as? Float {
            return v
        } else if let v = val as? Double {
            return Float(v)
        } else if let v = val as? Int16 {
            return Float(v)
        } else if let v = val as? Int32 {
            return Float(v)
        } else if let v = val as? UInt8 {
            return Float(v)
        } else {
            return 0.0
        }
    }

    /// Example: Get the full voxel data as [Float] (for Float32 images only)
    func voxelData() -> [Float]? {
        guard let img = niftiPtr else { return nil }
        let nx = Int(img.pointee.dim.1)
        let ny = Int(img.pointee.dim.2)
        let nz = Int(img.pointee.dim.3)
        let nvox = nx * ny * nz
        guard img.pointee.datatype == DT_FLOAT32, let data = img.pointee.data else { return nil }
        let floatData = data.assumingMemoryBound(to: Float.self)
        return Array(UnsafeBufferPointer(start: floatData, count: nvox))
    }
}
