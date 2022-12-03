# public interface ITextCrypto {
# 	public void begin(int base);
	
# 	public char decode(char c);
# 	public char encode(char c);
# }


COMPRESSED_CHAR_TABLE = [
		'Œ', 'œ', 'Ş', 'ş', '‘', '“', '”', '„', '…',
		'①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩', '⑪', '⑫', '⑬', '⑭', '⑮', '⑯', '⑰', '⑱', '⑲', '⑳',
		'⑴', '⑵', '⑶', '⑷', '⑸', '⑹', '⑺', '⑻', '⑼', '⑽', '⑾', '⑿', '⒀', '⒁', '⒂', '⒃', '⒄', '⒅', '⒆', '⒇',
		'･'
	]

COMPRESSED_CHAR_SPECIAL_BASE_INDEX = 256

CMD_BEGIN_9BIT = 0xF100


specialCharacters = {}
specialCharactersInv = {}


keyIter = 3;


charBuf = 0;
bufIdx = 0;
currentCharSize = 16;
currentCharMask = 0xFFFF;

