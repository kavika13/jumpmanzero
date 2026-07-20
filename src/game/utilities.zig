const std = @import("std");

// TODO: This utility function should be eliminated
fn TextLine(sText: []const u8, iTextLen: usize, sOut: []u8, iLine: i32) bool {
    var is_found = false;

    var iCR: c_int = 0;
    var iChars: usize = 0;

    sOut[iChars] = 0;

    var iLoop: usize = 0;
    while (iLoop < iTextLen) : (iLoop += 1) {
        if (iCR == iLine and sText[iLoop] != 10 and sText[iLoop] != 13 and iChars < sOut.len - 1) {
            is_found = true;
            sOut[iChars] = sText[iLoop];
            iChars += 1;
            sOut[iChars] = 0;
        }

        if (sText[iLoop] == 10 or sText[iLoop] == 13) {
            iCR += 1;

            if (sText[iLoop] == 13 and iLoop + 1 < iTextLen and sText[iLoop + 1] == 10) {
                // Handle Windows newline conventions, if present
                iLoop += 1;
            }
        }

        if (iCR > iLine) {
            break;
        }
    }

    return is_found;
}

// TODO: This utility function should be eliminated
// TODO: Take allocator as param
pub fn FileToString(io: std.Io, filename: [:0]const u8, sNewBuffer: *[*c]u8) usize {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, filename, std.heap.c_allocator, .unlimited) catch @panic("unable to read file"); // TODO: better error handling
    sNewBuffer.* = contents.ptr;
    return contents.len;
}

// TODO: This utility function should be eliminated
pub fn GetFileLine(io: std.Io, sOut: [*c]u8, sOutSize: usize, filename: [:0]const u8, iLine: c_int) bool {
    var is_found = false;
    var sTemp = std.mem.zeroes([20]u8);
    var sData: [*c]u8 = null;

    const iLen: usize = FileToString(io, filename, &sData);
    defer if (iLen != 0) std.heap.c_allocator.free(sData[0..iLen]);

    if (TextLine(sData[0..iLen], iLen, sTemp[0..], iLine)) {
        is_found = true;
        @memcpy(sOut[0..@min(sOutSize, sTemp.len)], &sTemp);
    }

    return is_found;
}
