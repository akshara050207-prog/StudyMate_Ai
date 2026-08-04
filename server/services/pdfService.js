const pdfParse = require("pdf-parse");
let Tesseract;
try {
  Tesseract = require("tesseract.js");
} catch (e) {
  Tesseract = null;
}

/**
 * Validates if a word is a real readable English document word.
 * Returns false if it's PDF binary noise (e.g. bpgp, ICCBased, DCTDecode, 0000000000 65535, hex codes).
 */
function isValidDocumentWord(word) {
  const cleanW = word.trim();
  if (cleanW.length < 2 || cleanW.length > 35) return false;

  const lower = cleanW.toLowerCase();
  const bannedKeywords = new Set([
    'rgb', 'devicergb', 'devicegray', 'devicecmyk', 'width', 'height', 'length',
    'mediabox', 'cropbox', 'procset', 'colorspace', 'xobject', 'flatedecode',
    'dctdecode', 'iccbased', 'fontdescriptor', 'basefont', 'subtype', 'fontmatrix',
    'catalog', 'pages', 'page', 'type', 'contents', 'kids', 'count', 'trailer',
    'startxref', 'xref', 'stream', 'endstream', 'endobj', 'obj', 'filter',
    'widths', 'encoding', 'pdf', 'bpgp', 'adobe', 'identity', 'jfif'
  ]);

  if (bannedKeywords.has(lower)) return false;

  // Reject strings with slashes, backslashes, quotes, or binary markers
  if (cleanW.includes('/') || cleanW.includes('\\') || cleanW.includes("'") || cleanW.includes('"') || cleanW.includes('`')) {
    return false;
  }

  // Pure letters and standard punctuation
  if (/^[a-zA-Z.,?!-]+$/.test(cleanW)) return true;

  // Words with digits must look like valid numbers/years (e.g. 2026, 100, Step1)
  if (/^[a-zA-Z0-9.,?!-]+$/.test(cleanW)) {
    const digitCount = (cleanW.match(/\d/g) || []).length;
    const letterCount = (cleanW.match(/[a-zA-Z]/g) || []).length;
    if (digitCount > 0 && letterCount > 0 && digitCount > 2) return false;
    return true;
  }

  return false;
}

/**
 * Extracts and cleans PDF text from buffer.
 * Completely strips %PDF headers, objects, streams, ICCBased profiles, DCTDecode images, and binary byte noise.
 * Performs OCR fallback if selectable text is below 50 characters.
 */
async function extractCleanPdfText(dataBuffer) {
  if (!dataBuffer || dataBuffer.length === 0) {
    return "";
  }

  let rawText = "";
  try {
    const pdfData = await pdfParse(dataBuffer);
    rawText = pdfData.text || "";
  } catch (err) {
    console.warn("pdf-parse fallback warning:", err.message);
  }

  const cleanExtractedText = (input) => {
    if (!input || input.trim().length === 0) return "";
    const pdfBlacklistPattern = new RegExp(
      '(/Type|/Pages|/Catalog|/Font|/Length|/Filter|/FlateDecode|/DCTDecode|/ICCBased|/MediaBox|/Resources|/ProcSet|/ColorSpace|/Parent|/Contents|/Kids|/Count|/FontDescriptor|/Widths|/BaseFont|/Subtype|/Image|/XObject|stream|endstream|endobj|obj|xref|trailer|startxref|%PDF-[0-9.]+|\\b\\d+\\s+\\d+\\s+obj\\b|\\b\\d+\\s+\\d+\\s+R\\b)',
      'gi'
    );
    let cleaned = input.replace(pdfBlacklistPattern, ' ');
    cleaned = cleaned.replace(/[^\x20-\x7E\n\r\t]/g, ' ');
    const words = cleaned
      .split(/\s+/)
      .filter((w) => isValidDocumentWord(w));
    return words.join(' ').trim();
  };

  let cleanedText = cleanExtractedText(rawText);

  // If extracted selectable text is less than 50 characters, perform OCR first!
  if (cleanedText.length < 50 && Tesseract) {
    console.log("ℹ️ Selectable text under 50 characters. Performing OCR fallback on document image buffer...");
    try {
      const ocrResult = await Tesseract.recognize(dataBuffer, "eng");
      const ocrText = ocrResult?.data?.text || "";
      cleanedText = cleanExtractedText(ocrText);
    } catch (ocrErr) {
      console.warn("OCR recognition warning:", ocrErr.message);
    }
  }

  if (cleanedText.length < 50) {
    return "";
  }

  return cleanedText;
}

module.exports = {
  extractCleanPdfText,
  isValidDocumentWord,
};

