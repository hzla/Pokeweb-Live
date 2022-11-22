/*

Copyright (C) 2018 hack64.net

*/

if(!Array.prototype.fill)
{
    var fill = function(v, start, end)
    {
        for(var i = start; i < end; i++)
        {
            this[i] = v;
        }
    }

    Array.prototype.fill = fill;
    Uint8Array.prototype.fill = fill;
}

(function(_this){
/*************/

const IN_WORKER = (typeof WorkerGlobalScope !== 'undefined' && self instanceof WorkerGlobalScope);
const LIB_PATH = '/jscripts/libpatch.js';

_this.applyPatch = applyPatch;
_this.applyPatchAsync = applyPatchAsync;

const ERR_PATCH_CHECKSUM = 'Patch checksum mismatch - patch file may be corrupt';
const ERR_SOURCE_CHECKSUM = 'Source checksum mismatch - patch is not meant for this ROM';
const ERR_TARGET_CHECKSUM = 'Target checksum mismatch';
const ERR_UNKNOWN_FORMAT = 'Unknown patch format';
const ERR_FORMAT_VERSION = 'Unhandled format version';
const ERR_GENERIC_DECODE = 'Decoding error';
const ERR_UNIMPLEMENTED = 'Unimplemented feature';

if(!_this.performance)
{
    _this.performance = {
        now: function()
        {
            console.log('performance object unavailable');
            return 1;
        }
    }
}

const CRC32Table = (function()
{
    var table = [];

    for(var i = 0; i < 256; i++)
    {
        var crc = i;

        for(var j = 0; j < 8; j++)
        {
            crc = (crc & 1) ? (crc >>> 1) ^ 0xEDB88320 : (crc >>> 1)
        }

        table.push(crc >>> 0);
    }

    return table;
})();

function crc32(arr, offs, size)
{
    var crc = 0xFFFFFFFF;

    for(var i = 0; i < size; i++)
    {
        crc = (CRC32Table[(crc & 0xFF) ^ arr[offs + i]] ^ (crc >>> 8)) >>> 0;
    }

    return (~crc) >>> 0;
}

function adler32(arr, offs, size)
{
    var a = 1, b = 0;

    for(var i = 0; i < size; i++)
    {
        a = (a + arr[offs + i]) % 65521;
        b = (b + a) % 65521;
    }

    return ((b << 16) | a) >>> 0;
}

function strtest(u8arr, str)
{
    for(var i = 0; i < str.length; i++)
    {
        if(u8arr[i] != str.charCodeAt(i))
        {
            return false;
        }
    }
    return true;
}

function bytecopy(dst, dstOffs, src, srcOffs, size)
{
    var subsrc = src.subarray(srcOffs, srcOffs + size);
    dst.set(subsrc, dstOffs);
}

function byteswap(u8arr, offs, size)
{
    var sub = u8arr.subarray(offs, offs + size);

    for(var i = 0; i < sub.byteLength; i += 2)
    {
        var t = sub[i];
        sub[i] = sub[i+1];
        sub[i+1] = t;
    }
}

function applyPatch(sourceData, patchData, ignoreChecksums)
{
    ignoreChecksums = ignoreChecksums || false;
    var header = new Uint8Array(patchData);
    
    var formats = [
        { sig: 'APS10',        name: 'aps',    applyPatch: applyPatchAPS },
        { sig: 'BPS1',         name: 'bps',    applyPatch: applyPatchBPS },
        { sig: 'PATCH',        name: 'ips',    applyPatch: applyPatchIPS },
        { sig: 'PPF',          name: 'ppf',    applyPatch: applyPatchPPF },
        { sig: 'UPS1',         name: 'ups',    applyPatch: applyPatchUPS },
        { sig: '\xD6\xC3\xC4', name: 'vcdiff', applyPatch: applyPatchVCD },
        { sig: 'PMSR',         name: 'mod',    applyPatch: applyPatchMOD },
        { sig: 'Yay0',         name: 'mod',    applyPatch: applyPatchMOD }
    ];

    for(var i in formats)
    {
        var fmt = formats[i];

        if(strtest(header, fmt.sig))
        {
            var timeStart, timeEnd;
            var targetData;

            console.log('libpatch: test applying ' + fmt.name + ' patch...');
            timeStart = _this.performance.now();
            targetData = fmt.applyPatch(sourceData, patchData, ignoreChecksums);
            timeEnd = _this.performance.now();
            console.log('libpatch: took ' + (timeEnd - timeStart).toFixed(3) + 'ms');
            return targetData;
        }
    }

    throw new Error(ERR_UNKNOWN_FORMAT);
}

function applyPatchAsync(sourceData, patchData, config)
{
    var patchWorker = new Worker(applyPatchAsync.WORKER_URL);

    var ignoreChecksums = config.ignoreChecksums || false;

    var onpatchend = config.onpatchend || null;
    var onprogress = config.onprogress || null;
    var onerror = config.onerror || null;
    
    var callbacks = {
        'patchend': onpatchend,
        'progress': onprogress,
        'error':    onerror
    };

    patchWorker.onmessage = function(e)
    {
        var msg = e.data;

        if(callbacks[msg.evtType])
        {
            callbacks[msg.evtType](msg.param);
        }
    }

    var msg = {
        sourceData: sourceData,
        patchData: patchData,
        ignoreChecksums: ignoreChecksums
    };

    patchWorker.postMessage(msg);
}

applyPatchAsync.WORKER_URL = (function()
{
    if(IN_WORKER)
    {
        return null;
    }

    var WORKER_SOURCE = [
    'importScripts("https://hack64.net'+LIB_PATH+'", "https://hack64.net/jscripts/lzma.js");',
    '',
    'self.onmessage = function(e)',
    '{',
    '    var sourceData = e.data.sourceData;',
    '    var patchData = e.data.patchData;',
    '    var ignoreChecksums = e.data.ignoreChecksums;',
    '    ',
    '    try',
    '    {',
    '        var targetData = applyPatch(sourceData, patchData, ignoreChecksums);',
    '        self.postMessage({ evtType: \'patchend\', param: targetData });',
    '    }',
    '    catch(e)',
    '    {',
    '        console.log(e);',
    '        self.postMessage({ evtType: \'error\', param: e.message });',
    '    }',
    '',
    '    self.close();',
    '}'].join('');
    
    var workerURL = URL.createObjectURL(new Blob([WORKER_SOURCE]));

    return workerURL;
})();


function ProgressBroadcaster()
{
    this.ratio = 0.0;
}

ProgressBroadcaster.prototype.update = function(ratio)
{
    if(IN_WORKER && (ratio - this.ratio) >= 0.01)
    {
        // post progress update to the main thread if ratio has increased by 1+%
        self.postMessage({ evtType: 'progress', param: ratio });
        this.ratio = ratio;
    }
}

function PatchStream(ab, littleEndian)
{
    this.ab = ab;
    this.u8 = new Uint8Array(ab);
    this.dv = new DataView(ab);
    this.offset = 0;
    this.littleEndian = littleEndian || false;
}

PatchStream.prototype = {
    seek: function(offset)
    {
        this.offset = offset;
    },
    skip: function(numBytes)
    {
        this.offset += numBytes;
    },
    isEOF: function()
    {
        return (this.offset >= this.ab.byteLength);
    },
    readBytes: function(dst, dstOffs, numBytes)
    {
        // read bytes into a u8 array
        bytecopy(dst, dstOffs, this.u8, this.offset, numBytes);
        this.skip(numBytes);
    },
    _readInt: function(dvType, numBytes)
    {
        var val = this.dv[dvType](this.offset, this.littleEndian);
        this.offset += numBytes;
        return val;
    },
    readU8: function()
    {
        return this._readInt('getUint8', 1);
    },
    readU16: function()
    {
        return this._readInt('getUint16', 2);
    },
    readU24: function()
    {
        if(!this.littleEndian)
        {
            return (this.readU16() << 8) | this.readU8();
        }
        return this.readU16() | (this.readU8() << 16);
    },
    readU32: function()
    {
        return this._readInt('getUint32', 4);
    },
    readU64: function()
    {
        var a = this.readU32();
        var b = this.readU32();

        if(this.littleEndian)
        {
            return ((b * 0x100000000) + a);
        }

        return ((a * 0x100000000) + b);
    }
};

// APS
// http://n64.icequake.net/mirror/www.dextrose.com/files/n64/ips_tools/bb-aps12.zip

const APS_MODE_SIMPLE = 0;
const APS_MODE_N64 = 1;

const APS_ENC_SIMPLE = 0;

const APS_N64_FMT_V64 = 0;
const APS_N64_FMT_Z64 = 1;

function applyPatchAPS(sourceData, patchData, ignoreChecksums)
{
    var patchStream = new PatchStream(patchData, true);
    var sourceDV = new DataView(sourceData);
    var sourceU8 = new Uint8Array(sourceData);

    var progress = new ProgressBroadcaster();

    patchStream.seek(0x05); // skip magic

    var patchMode = patchStream.readU8();
    var encodingMethod = patchStream.readU8();

    patchStream.skip(0x32); // skip description

    var targetSize = 0;

    if(patchMode == APS_MODE_SIMPLE)
    {
        // dunno if this is the right position
        targetSize = patchStream.readU32();
    }
    else if(patchMode == APS_MODE_N64)
    {
        var fileFormat = patchStream.readU8();

        patchStream.littleEndian = false;
        var cartId = patchStream.readU16();
        var countryCode = patchStream.readU8();
        var crc1 = patchStream.readU32();
        var crc2 = patchStream.readU32();
        patchStream.littleEndian = true;

        patchStream.skip(0x05);
        targetSize = patchStream.readU32();

        if(!ignoreChecksums)
        {
            if(fileFormat == APS_N64_FMT_V64) // meh
            {
                byteswap(sourceU8, 0, 0x40);
            }

            var srcCartId = sourceDV.getUint16(0x3C);
            var srcCountryCode = sourceU8[0x3E];
            var srcCrc1 = sourceDV.getUint32(0x10);
            var srcCrc2 = sourceDV.getUint32(0x14);
            
            if(fileFormat == APS_N64_FMT_V64)
            {
                byteswap(sourceU8, 0, 0x40);
            }

            if(crc1 != srcCrc1 ||
               crc2 != srcCrc2 ||
               cartId != srcCartId ||
               srcCountryCode != countryCode)
            {
                throw new Error(ERR_SOURCE_CHECKSUM);
            }
        }
    }
    else
    {
        // unknown mode
        throw new Error(ERR_UNIMPLEMENTED); 
    }

    if(encodingMethod != APS_ENC_SIMPLE)
    {
        // unknown encoding method
        throw new Error(ERR_UNIMPLEMENTED);
    }

    var targetData = new ArrayBuffer(targetSize);
    var targetU8 = new Uint8Array(targetData);
    bytecopy(targetU8, 0, sourceU8, 0, sourceU8.byteLength);

    while(!patchStream.isEOF())
    {
        var targetOffs = patchStream.readU32();
        var length = patchStream.readU8();

        if(length != 0)
        {
            patchStream.readBytes(targetU8, targetOffs, length);
        }
        else
        {
            var runByte = patchStream.readU8();
            var runLength = patchStream.readU8();

            targetU8.fill(runByte, targetOffs, targetOffs + runLength);
        }
    }

    return targetData;
}

// UPS
// http://individual.utoronto.ca/dmeunier/ups-spec.pdf

function UPSPatchStream(ab)
{
    PatchStream.call(this, ab, true);
}
UPSPatchStream.prototype = Object.create(PatchStream.prototype);

UPSPatchStream.prototype.readnum = function()
{
    var num = 0, shift = 1;
    while(true)
    {
        var x = this.u8[this.offset++];
        num += (x & 0x7F) * shift;
        if(x & 0x80) break;
        shift <<= 7;
        num += shift;
    }
    return num;
}

function applyPatchUPS(sourceData, patchData, ignoreChecksums)
{
    var patchStream = new UPSPatchStream(patchData);
    var sourceU8 = new Uint8Array(sourceData);
    var progress = new ProgressBroadcaster();

    var checksumOffs = patchData.byteLength - 12;

    patchStream.seek(checksumOffs);

    var sourceChecksum = patchStream.readU32();
    var targetChecksum = patchStream.readU32();
    var patchChecksum = patchStream.readU32();

    if(!ignoreChecksums)
    {
        if(sourceChecksum != crc32(sourceU8, 0, sourceU8.byteLength))
        {
            throw new Error(ERR_SOURCE_CHECKSUM);
        }
    
        if(patchChecksum != crc32(patchStream.u8, 0, patchData.byteLength - 4))
        {
            throw new Error(ERR_PATCH_CHECKSUM);
        }
    }

    patchStream.seek(0x04);

    var inputFileSize = patchStream.readnum();
    var outputFileSize = patchStream.readnum();

    var targetData = new ArrayBuffer(outputFileSize);
    var targetU8 = new Uint8Array(targetData);
    bytecopy(targetU8, 0, sourceU8, 0, sourceU8.byteLength);
    
    var targetOffs = 0;

    while(patchStream.offset < checksumOffs)
    {
        targetOffs += patchStream.readnum();

        var x;
        while(x = patchStream.readU8())
        {
            targetU8[targetOffs++] ^= x;
        }
        targetOffs++;

        progress.update(patchStream.offset / patchData.byteLength);
    }

    if(!ignoreChecksums && targetChecksum != crc32(targetU8, 0, targetU8.byteLength))
    {
        throw new Error(ERR_TARGET_CHECKSUM);
    }

    return targetData;
}

// MOD (Star Rod Patch)
// http://origami64.net/attachment.php?aid=790

function applyPatchMOD(sourceData, patchData)
{
    var patchStream = new PatchStream(patchData);
    var sourceU8 = new Uint8Array(sourceData);
    
    if(strtest(patchStream.u8, 'Yay0'))
    {
        patchData = yay0decode(patchData);
        patchStream = new PatchStream(patchData);
    }

    patchStream.seek(4);

    var count = patchStream.readU32();

    // precalculate target size
    var targetSize = sourceData.byteLength;

    for(var i = 0; i < count; i++)
    {
        var targetOffs = patchStream.readU32();
        var length = patchStream.readU32();
        var limit = targetOffs + length;
        if(limit > targetSize)
        {
            targetSize = limit;
        }
        patchStream.skip(length);
    }

    var targetData = new ArrayBuffer(targetSize);
    var targetU8 = new Uint8Array(targetData);
    bytecopy(targetU8, 0, sourceU8, 0, sourceU8.byteLength);

    patchStream.seek(8);

    for(var i = 0; i < count; i++)
    {
        var targetOffs = patchStream.readU32();
        var length = patchStream.readU32();
        patchStream.readBytes(targetU8, targetOffs, length);
    }

    return targetData;
}

function yay0decode(src)
{
    var srcDV = new DataView(src);
    var srcU8 = new Uint8Array(src);

    var dstSize = srcDV.getUint32(0x04);
    var pairPos = srcDV.getUint32(0x08);
    var dataPos = srcDV.getUint32(0x0C);
    var bitsPos = 0x10;

    var dst = new ArrayBuffer(dstSize);
    var dstU8 = new Uint8Array(dst);

    var shift = 0, bits = 0, dstPos = 0;
    
    while(dstPos < dstSize)
    {
        if(shift == 0)
        {
            bits = srcDV.getUint32(bitsPos);
            bitsPos += 4;
            shift = 32;
        }

        if(bits & 0x80000000)
        {
            dstU8[dstPos++] = srcU8[dataPos++];
        }
        else
        {
            var pair = srcDV.getUint16(pairPos);
            pairPos += 2;

            var length = pair >> 12;
            var offset = dstPos - (pair & 0x0FFF) - 1;

            if(length == 0)
            {
                length = srcU8[dataPos++] + 18;
            }
            else
            {
                length += 2;
            }

            while(length--)
            {
                dstU8[dstPos++] = dstU8[offset++];
            }
        }

        bits <<= 1;
        shift--;
    }

    return dst;
}

// PPF
// https://www.romhacking.net/utilities/353/

function PPFPatchStream(ab)
{
    PatchStream.call(this, ab, true);
    this.version = 3.0;
    this.readAddress = this.readU64;
}
PPFPatchStream.prototype = Object.create(PatchStream.prototype);

PPFPatchStream.prototype.setVersion = function(version)
{
    this.readAddress = (version == 3.0) ? this.readU64 : this.readU32;
    this.version = version;
}

function applyPatchPPF(sourceData, patchData)
{
    var patchStream = new PPFPatchStream(patchData);

    var targetData = sourceData.slice(0);
    var targetU8 = new Uint8Array(targetData);

    var progress = new ProgressBroadcaster();

    patchStream.seek(0x03);

    var ppfVersionHi = patchStream.readU8() - 0x30;
    var ppfVersionLo = patchStream.readU8() - 0x30;
    var ppfVersion = ppfVersionHi + (ppfVersionLo / 10);

    patchStream.setVersion(ppfVersion);

    patchStream.skip(1); // skip unk byte
    patchStream.skip(0x32); // skip meta

    var origBinLength = 0; // v2, v3
    var imageType = 0; // v3
    var haveBlockCheck = false; // v3
    var haveUndoData = false; // v3

    switch(ppfVersion)
    {
    case 3.0:
        imageType = patchStream.readU8();
        haveBlockCheck = (patchStream.readU8() != 0);
        haveUndoData = (patchStream.readU8() != 0);
        patchStream.skip(1); //  reserved byte
        break;
    case 2.0:
        origBinLength = patchStream.readU32();
        haveBlockCheck = true; // always present in v2
        break;
    case 1.0:
        break;
    default:
        throw new Error(ERR_FORMAT_VERSION);
    }

    if(haveBlockCheck)
    {
        patchStream.skip(0x400); // ignore validation block
    }

    while(!patchStream.isEOF())
    {
        var targetOffs = patchStream.readAddress();
        var length = patchStream.readU8();

        patchStream.readBytes(targetU8, targetOffs, length);

        if(haveUndoData)
        {
            patchStream.skip(length); // skip undo data
        }

        progress.update(patchStream.offset / patchData.byteLength);
    }

    return targetData;
}

// IPS
// https://zerosoft.zophar.net/ips.php

function ipsPrecalculateTargetSize(sourceData, patchData)
{
    var patchStream = new PatchStream(patchData);
    var dstSize = sourceData.byteLength;

    patchStream.seek(0x05);

    while(patchStream.offset < patchData.byteLength - 3)
    {
        var targetOffs = patchStream.readU24();
        var length = patchStream.readU16();
        var endOffs = targetOffs + length;

        if(length != 0)
        {
            patchStream.skip(length);
        }
        else
        {
            var runLength = patchStream.readU16();
            patchStream.skip(1);
            endOffs += runLength;
        }

        if(endOffs > dstSize)
        {
            dstSize = endOffs;
        }
    }

    return dstSize;
}

function applyPatchIPS(sourceData, patchData)
{
    var patchStream = new PatchStream(patchData);

    var targetSize = ipsPrecalculateTargetSize(sourceData, patchData);
    var targetData = new ArrayBuffer(targetSize);
    var targetU8 = new Uint8Array(targetData);
    targetU8.set(new Uint8Array(sourceData));

    var progress = new ProgressBroadcaster();

    patchStream.seek(0x05);

    while(patchStream.offset < patchData.byteLength - 3)
    {
        var targetOffs = patchStream.readU24();
        var length = patchStream.readU16();

        if(length != 0)
        {
            // copy
            patchStream.readBytes(targetU8, targetOffs, length);
        }
        else
        {
            // fill
            var runLength = patchStream.readU16();
            var runByte = patchStream.readU8();

            targetU8.fill(runByte, targetOffs, targetOffs + runLength);
        }

        progress.update(patchStream.offset / patchData.byteLength);
    }

    return targetData;
}

// BPS
// https://www.romhacking.net/documents/746/

function BPSPatchStream(ab)
{
    PatchStream.call(this, ab, true);
}
BPSPatchStream.prototype = Object.create(PatchStream.prototype);

BPSPatchStream.prototype.readnum = function()
{
    var num = 0, shift = 1;
    while(true)
    {
        var x = this.u8[this.offset++];
        num += (x & 0x7F) * shift;
        if(x & 0x80) break;
        shift <<= 7;
        num += shift;
    }
    return num;
}

function applyPatchBPS(sourceData, patchData, ignoreChecksums)
{
    var sourceU8 = new Uint8Array(sourceData);
    var patchStream = new BPSPatchStream(patchData);

    var targetData = null;
    var targetU8 = null;

    var progress = new ProgressBroadcaster();

    var sourceSize = 0, targetSize = 0, metadataSize = 0;
    var targetOffs = 0, sourceRelativeOffs = 0, targetRelativeOffs = 0;

    var checksumOffs = patchData.byteLength - 12;

    patchStream.seek(checksumOffs);
    var sourceChecksum = patchStream.readU32();
    var targetChecksum = patchStream.readU32();
    var patchChecksum = patchStream.readU32();

    if(!ignoreChecksums)
    {
        if(sourceChecksum != crc32(sourceU8, 0, sourceU8.byteLength))
        {
            throw new Error(ERR_SOURCE_CHECKSUM);
        }
    
        if(patchChecksum != crc32(patchStream.u8, 0, patchData.byteLength - 4))
        {
            throw new Error(ERR_PATCH_CHECKSUM);
        }
    }

    patchStream.seek(0x04);

    sourceSize = patchStream.readnum();
    targetSize = patchStream.readnum();
    metadataSize = patchStream.readnum();

    patchStream.skip(metadataSize);

    targetData = new ArrayBuffer(targetSize);
    targetU8 = new Uint8Array(targetData);

    while(patchStream.offset < checksumOffs)
    {
        var data = patchStream.readnum();
        var command = data & 0x3;
        var length = (data >>> 2) + 1;

        switch(command)
        {
        case 0: // source read
            bytecopy(targetU8, targetOffs, sourceU8, targetOffs, length);
            targetOffs += length;
            break;
        case 1: // target read
            patchStream.readBytes(targetU8, targetOffs, length);
            targetOffs += length;
            break;
        case 2: // source copy
            data = patchStream.readnum();
            sourceRelativeOffs += (data & 1 ? -1 : +1) * (data >>> 1);
            bytecopy(targetU8, targetOffs, sourceU8, sourceRelativeOffs, length);
            targetOffs += length;
            sourceRelativeOffs += length;
            break;
        case 3: // target copy
            data = patchStream.readnum();
            targetRelativeOffs += (data & 1 ? -1 : +1) * (data >>> 1);
            while(length--)
            {
                targetU8[targetOffs++] = targetU8[targetRelativeOffs++];
            }
            break;
        default:
            throw new Error(ERR_GENERIC_DECODE)
        }

        progress.update(patchStream.offset / patchData.byteLength);
    }

    if(!ignoreChecksums && targetChecksum != crc32(targetU8, 0, targetU8.byteLength))
    {
        throw new Error(ERR_TARGET_CHECKSUM);
    }

    return targetData;
}

// VCDiff (xdelta)
// https://tools.ietf.org/html/rfc3284

// hdrIndicator
const VCD_DECOMPRESS = (1 << 0);
const VCD_CODETABLE  = (1 << 1);
const VCD_APPHEADER  = (1 << 2); // nonstandard?

// winIndicator
const VCD_SOURCE  = (1 << 0);
const VCD_TARGET  = (1 << 1);
const VCD_ADLER32 = (1 << 2);

// COPY address modes
const VCD_SELF = 0;
const VCD_HERE = 1;

// deltaIndicator - secondary compression
const VCD_DATACOMP = (1 << 0);
const VCD_INSTCOMP = (1 << 2);
const VCD_ADDRCOMP = (1 << 3);

const VCD_NOOP = 0, VCD_ADD = 1, VCD_RUN = 2, VCD_COPY = 3;

const VCDDefaultCodeTable = (function()
{
    var table = [];

    var empty = {inst: VCD_NOOP, size: 0, mode: 0};

    // 0
    table.push([{inst: VCD_RUN, size: 0, mode: 0}, empty]);

    // 1,18
    for(var size = 0; size <= 17; size++)
    {
        table.push([{inst: VCD_ADD, size: size, mode: 0}, empty]);
    }

    // 19,162
    for(var mode = 0; mode <= 8; mode++)
    {
        table.push([{inst: VCD_COPY, size: 0, mode: mode}, empty]);
        
        for(var size = 4; size <= 18; size++)
        {
            table.push([{inst: VCD_COPY, size: size, mode: mode}, empty]);
        }
    }

    // 163,234
    for(var mode = 0; mode <= 5; mode++)
    {
        for(var addSize = 1; addSize <= 4; addSize++)
        {
            for(var copySize = 4; copySize <= 6; copySize++)
            {
                table.push([{inst:  VCD_ADD, size: addSize,  mode: 0},
                            {inst: VCD_COPY, size: copySize, mode: mode}]);
            }
        }
    }

    // 235,246
    for(var mode = 6; mode <= 8; mode++)
    {
        for(var addSize = 1; addSize <= 4; addSize++)
        {
            table.push([{inst:  VCD_ADD, size: addSize, mode: 0},
                        {inst: VCD_COPY, size:       4, mode: mode}]);
        }
    }

    // 247,255
    for(var mode = 0; mode <= 8; mode++)
    {
        table.push([{inst: VCD_COPY, size: 4, mode: mode},
                    {inst:  VCD_ADD, size: 1, mode: 0}]); 
    }

    return table;
})();

function VCDStream(arrayBuffer, offset)
{
    PatchStream.call(this, arrayBuffer);
    this.offset = offset;
}

VCDStream.prototype = Object.create(PatchStream.prototype);

VCDStream.prototype.readnum = function()
{
    var num = 0, bits = 0;

    do {
        bits = this.readU8();
        num = (num << 7) + (bits & 0x7F); 
    } while(bits & 0x80);

    return num;
}

function VCDCache(config)
{
    this.near = new Array(config.nearSize);
    this.nearSize = config.nearSize;
    this.nextSlot = 0;

    this.same = new Array(config.sameSize * 256);
    this.sameSize = config.sameSize;
    
    this.reset();
}

VCDCache.prototype.reset = function()
{
    this.nextSlot = 0;
    this.near.fill(0);
    this.same.fill(0);
}

VCDCache.prototype.update = function(addr)
{
    if(this.nearSize > 0)
    {
        this.near[this.nextSlot] = addr;
        this.nextSlot = (this.nextSlot + 1) % this.nearSize;
    }

    if(this.sameSize > 0)
    {
        this.same[addr % (this.sameSize * 256)] = addr;
    }
}

VCDCache.prototype.decodeAddress = function(copyAddrStream, mode, here)
{
    var addr = 0;
    var m = 0;

    if(mode == VCD_SELF)
    {
        addr = copyAddrStream.readnum();
    }
    else if(mode == VCD_HERE)
    {
        addr = here - copyAddrStream.readnum();
    }
    else if((m = (mode - 2)) >= 0 && m < this.nearSize) // near cache
    {
        addr = this.near[m] + copyAddrStream.readnum();
    }
    else // same cache
    {
        m = mode - (2 + this.nearSize);
        addr = this.same[m*256 + copyAddrStream.readU8()];
    }
    
    this.update(addr);
    return addr;
}

function VCDHeader(patchStream)
{
    patchStream.skip(4); // skip over the magic number

    this.indicator = patchStream.readU8();
    this.secDecompressorId = 0;
    this.codeTableDataLength = 0;
    this.appDataLength = 0;

    if(this.indicator & VCD_DECOMPRESS)
    {
        this.secDecompressorId = patchStream.readU8();
        console.log("secondary decompressor:" + this.secDecompressorId);
    }

    if(this.indicator & VCD_CODETABLE)
    {
        this.codeTableDataLength = patchStream.readnum();
        console.log("code table is used");
    }

    if(this.indicator & VCD_APPHEADER)
    {
        // ignore app header data
        this.appDataLength = patchStream.readnum();
        patchStream.skip(this.appDataLength);
    }
}

function VCDWindowHeader(patchStream)
{
    this.indicator = patchStream.readU8();
    this.sourceSegmentLength = 0;
    this.sourceSegmentPosition = 0;
    this.adler32 = 0;
    this.haveChecksum = false;

    if(this.indicator & (VCD_SOURCE | VCD_TARGET))
    {
        this.sourceSegmentLength = patchStream.readnum();
        this.sourceSegmentPosition = patchStream.readnum();
    }

    this.deltaLength = patchStream.readnum();
    this.targetWindowLength = patchStream.readnum();
    this.deltaIndicator = patchStream.readU8(); // secondary compression
    
    this.dataLength = patchStream.readnum();
    this.instrsLength = patchStream.readnum();
    this.copysLength = patchStream.readnum();

    if(this.indicator & VCD_ADLER32) 
    {
        this.adler32 = patchStream.readU32();
        this.haveChecksum = true;
    }

    //if(this.deltaIndicator != 0)
    //{
    //    // deltaIndicator":7,
    //    console.log(JSON.stringify(this));
    //    throw new Error(ERR_UNIMPLEMENTED);
    //}
}

function vcdPrecalculateTargetSize(patchStream)
{
    var targetSize = 0;
    var header = new VCDHeader(patchStream);

    while(!patchStream.isEOF())
    {
        var winHeader = new VCDWindowHeader(patchStream);
        targetSize += winHeader.targetWindowLength;
        patchStream.skip(winHeader.dataLength + winHeader.copysLength + winHeader.instrsLength);
    }

    patchStream.offset = 0;
    return targetSize;
}

function applyPatchVCD(sourceData, patchData, ignoreChecksums)
{
    var sourceU8 = new Uint8Array(sourceData);
    var patchStream = new VCDStream(patchData, 0);

    var targetSize = vcdPrecalculateTargetSize(patchStream);
    var targetData = new ArrayBuffer(targetSize);
    var targetU8 = new Uint8Array(targetData);

    var progress = new ProgressBroadcaster();

    var header = new VCDHeader(patchStream);

    var cache = null;
    var codeTable = null;

    if(header.secDecompressorId != 0)
    {
        console.log("sec decompressor " + header.secDecompressorId);
        throw new Error(ERR_UNIMPLEMENTED); // secondary decompressor
    }

    if(header.codeTableDataLength == 0)
    {
        cache = new VCDCache({ nearSize: 4, sameSize: 3 });
        codeTable = VCDDefaultCodeTable;
    }
    else
    {
        console.log("code table");
        throw new Error(ERR_UNIMPLEMENTED); // custom code table
    }

    var targetWindowPosition = 0;

    while(!patchStream.isEOF())
    {
        var winHeader = new VCDWindowHeader(patchStream);

        var dataStream, instructionStream, copyAddrStream;

        if(winHeader.deltaIndicator & VCD_DATACOMP)
        {
            // TODO: secondary decompressor implementation here
        }
        else
        {
            dataStream = new VCDStream(patchData, patchStream.offset);
        }

        if(winHeader.deltaIndicator & VCD_INSTCOMP)
        {

        }
        else
        {
            instructionStream = new VCDStream(patchData, dataStream.offset + winHeader.dataLength);
        }

        if(winHeader.deltaIndicator & VCD_ADDRCOMP)
        {

        }
        else
        {
            copyAddrStream = new VCDStream(patchData, instructionStream.offset + winHeader.instrsLength);
        }

        var instructionStreamEndOffs = copyAddrStream.offset;

        var targetWindowOffs = 0; // offset within the current target window

        var copySourceU8 = null;

        if(winHeader.indicator & VCD_SOURCE)
        {
            copySourceU8 = sourceU8;
        }
        else if(winHeader.indicator & VCD_TARGET)
        {
            copySourceU8 = targetU8;
        }

        cache.reset();

        while(instructionStream.offset < instructionStreamEndOffs)
        {
            var codeTableIndex = instructionStream.readU8();
            var code = codeTable[codeTableIndex];

            for(var i = 0; i <= 1; i++)
            {
                var op = code[i].inst;

                if(op == VCD_NOOP)
                {
                    continue;
                }

                var length = code[i].size || instructionStream.readnum();

                switch(op)
                {
                case VCD_ADD:
                    dataStream.readBytes(targetU8, targetWindowPosition + targetWindowOffs, length);
                    targetWindowOffs += length;
                    break;
                case VCD_RUN:
                    var runByte = dataStream.readU8();
                    var offs = targetWindowPosition + targetWindowOffs;
                    targetU8.fill(runByte, offs, offs + length);
                    targetWindowOffs += length;
                    break;
                case VCD_COPY:
                    var addr = cache.decodeAddress(copyAddrStream, code[i].mode, winHeader.sourceSegmentLength + targetWindowOffs);
                    var absAddr = 0;

                    // source segment and target segment are treated as if they're concatenated
                    if(addr >= winHeader.sourceSegmentLength)
                    {
                        absAddr = targetWindowPosition + (addr - winHeader.sourceSegmentLength);
                        copySourceU8 = targetU8;
                    }
                    else
                    {
                        absAddr = winHeader.sourceSegmentPosition + addr;
                        if(winHeader.indicator & VCD_SOURCE)
                        {
                            copySourceU8 = sourceU8;
                        }
                    }

                    while(length--)
                    {
                        targetU8[targetWindowPosition + targetWindowOffs++] = copySourceU8[absAddr++];
                    }
                    break;
                }
            }

            progress.update((targetWindowPosition + targetWindowOffs) / targetSize);
        }

        if(winHeader.haveChecksum && !ignoreChecksums)
        {
            var testAdler32 = adler32(targetU8, targetWindowPosition, winHeader.targetWindowLength);

            if(winHeader.adler32 != testAdler32)
            {
                throw new Error(ERR_TARGET_CHECKSUM);
            }
        }

        patchStream.skip(winHeader.dataLength + winHeader.copysLength + winHeader.instrsLength);
        targetWindowPosition += winHeader.targetWindowLength;
    }

    return targetData;
}

})(this);