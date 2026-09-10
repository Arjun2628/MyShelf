import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';

/// Provides sample preloaded EPUB books for testing and demoing the reader.
class SampleBooksProvider {
  final OpenEpubUseCase _openEpubUseCase;

  const SampleBooksProvider(this._openEpubUseCase);

  /// Builds and opens a demo Malayalam EPUB book ("ചെമ്മീൻ" / Chemmeen excerpt).
  Future<Book> getMalayalamSampleBook() async {
    final zipBytes = _createZipBytes({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
      'OEBPS/content.opf': '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>ചെമ്മീൻ (Chemmeen)</dc:title>
    <dc:creator>തകഴി ശിവശങ്കരപ്പിള്ള (Thakazhi)</dc:creator>
    <dc:language>ml</dc:language>
    <dc:description>മലയാള സാഹിത്യത്തിലെ പ്രശസ്തമായ നോവൽ.</dc:description>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch3" href="text/ch3.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
    <itemref idref="ch3"/>
  </spine>
</package>''',
      'OEBPS/toc.ncx': '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="p1" playOrder="1">
      <navLabel><text>അദ്ധ്യായം 1: കടപ്പുറവും കാറ്റും</text></navLabel>
      <content src="text/ch1.xhtml"/>
    </navPoint>
    <navPoint id="p2" playOrder="2">
      <navLabel><text>അദ്ധ്യായം 2: കറുത്തമ്മയും പരീക്കുട്ടിയും</text></navLabel>
      <content src="text/ch2.xhtml"/>
    </navPoint>
    <navPoint id="p3" playOrder="3">
      <navLabel><text>അദ്ധ്യായം 3: കടലിന്റെ മക്കൾ</text></navLabel>
      <content src="text/ch3.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''',
      'OEBPS/text/ch1.xhtml': '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>അദ്ധ്യായം ഒന്ന്</title></head>
<body>
  <h1>അദ്ധ്യായം ഒന്ന്: കടപ്പുറവും കാറ്റും</h1>
  <p>കടൽ ഇളകിമറിയുകയാണ്. തിരമാലകൾ അലറിയടുക്കുന്നു. പടിഞ്ഞാറൻ കാറ്റിൽ ഉപ്പുരസവും മീനിന്റെ മണവും നിറഞ്ഞുനിന്നു.</p>
  <p>തീരത്ത് വള്ളങ്ങൾ നിരത്തിയിട്ടിരിക്കുന്നു. വലകൾ ഉണക്കാനിട്ടിരിക്കുന്നു. കടപ്പുറത്തെ ജീവിതം കടലമ്മയുടെ കാരുണ്യത്തിലാണ് നിലനിൽക്കുന്നത്.</p>
  <blockquote>
    <p>"കടലമ്മ ചതിക്കില്ല മക്കളേ, നേരും നെറിയുമുള്ളവനെ കടലമ്മ കാക്കും."</p>
  </blockquote>
  <p>ചെമ്പൻകുഞ്ഞ് തീരത്ത് നിന്ന് ആഴക്കടലിലേക്ക് നോക്കി. മനസ്സിൽ വലിയൊരു വള്ളവും വലയും സ്വന്തമാക്കണമെന്ന മോഹം തിളച്ചുപൊന്തുകയായിരുന്നു.</p>
</body>
</html>''',
      'OEBPS/text/ch2.xhtml': '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>അദ്ധ്യായം രണ്ട്</title></head>
<body>
  <h1>അദ്ധ്യായം രണ്ട്: കറുത്തമ്മയും പരീക്കുട്ടിയും</h1>
  <p>തീരത്തെ മണൽപ്പരപ്പിലൂടെ കറുത്തമ്മ നടന്നു. ദൂരെ പരീക്കുട്ടിയുടെ പാട്ട് കാറ്റിൽ ഒഴുകിവരുന്നുണ്ടായിരുന്നു.</p>
  <p>അവരുടെ സൗഹൃദം ബാല്യകാലം മുതലേ തുടങ്ങിയതാണ്. എന്നാൽ സമൂഹത്തിന്റെ മതിലുകൾ അവർക്കിടയിൽ വലിയൊരു ചോദ്യചിഹ്നമായി നിന്നു.</p>
  <hr/>
  <p>പരീക്കുട്ടി ചോദിച്ചു: <i>"കറുത്തമ്മേ, നീ എന്നെ മറക്കുമോ?"</i></p>
  <p>കറുത്തമ്മയുടെ കണ്ണുകൾ നിറഞ്ഞു തുളുമ്പി. അവൾ മറുപടി പറഞ്ഞില്ല, മൗനമായിരുന്നു അവളുടെ ഭാഷ.</p>
</body>
</html>''',
      'OEBPS/text/ch3.xhtml': '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>അദ്ധ്യായം മൂന്ന്</title></head>
<body>
  <h1>അദ്ധ്യായം മൂന്ന്: കടലിന്റെ മക്കൾ</h1>
  <p>രാവിലെ തന്നെ മുക്കുവന്മാർ കടലിലിറങ്ങി. പങ്കായങ്ങളുടെ താളവും കടൽപ്പാട്ടുകളും അന്തരീക്ഷത്തിൽ മുഴങ്ങി.</p>
  <p>മീൻപിടുത്തം കേവലം ഒരു തൊഴിലല്ല, അതൊരു ജീവിതരീതിയാണ്. ഓരോ യാത്രയിലും തിരികെയെത്തുമെന്ന പ്രതീക്ഷ മാത്രമാണ് അവരുടെ കൈമുതൽ.</p>
  <ul>
    <li>കടലിലെ കാറ്റ്</li>
    <li>ആഴക്കടലിലെ ചൂണ്ട</li>
    <li>തീരത്തെ കാത്തിരിപ്പ്</li>
  </ul>
</body>
</html>''',
    });

    return _openEpubUseCase.fromBytes(zipBytes, bookId: 'sample_chemmeen');
  }

  /// Builds and opens a demo English EPUB book ("Alice in Wonderland").
  Future<Book> getEnglishSampleBook() async {
    final zipBytes = _createZipBytes({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
      'OEBPS/content.opf': '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Alice's Adventures in Wonderland</dc:title>
    <dc:creator>Lewis Carroll</dc:creator>
    <dc:language>en</dc:language>
    <dc:description>A classic tale of curiosity and wonderland.</dc:description>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''',
      'OEBPS/toc.ncx': '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="p1" playOrder="1">
      <navLabel><text>Chapter I: Down the Rabbit-Hole</text></navLabel>
      <content src="text/ch1.xhtml"/>
    </navPoint>
    <navPoint id="p2" playOrder="2">
      <navLabel><text>Chapter II: The Pool of Tears</text></navLabel>
      <content src="text/ch2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''',
      'OEBPS/text/ch1.xhtml': '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter I</title></head>
<body>
  <h1>Chapter I: Down the Rabbit-Hole</h1>
  <p>Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, <i>'and what is the use of a book,'</i> thought Alice <i>'without pictures or conversations?'</i></p>
  <p>So she was considering in her own mind whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a <b>White Rabbit with pink eyes</b> ran close by her.</p>
  <blockquote>
    <p>"Oh dear! Oh dear! I shall be late!"</p>
  </blockquote>
  <p>There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, but when the Rabbit actually took a watch out of its waistcoat-pocket, Alice started to her feet!</p>
</body>
</html>''',
      'OEBPS/text/ch2.xhtml': '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter II</title></head>
<body>
  <h1>Chapter II: The Pool of Tears</h1>
  <p><i>'Curiouser and curiouser!'</i> cried Alice (she was so much surprised, that for the moment she quite forgot how to speak good English); <i>'now I am opening out like the largest telescope that ever was! Good-bye, feet!'</i></p>
  <p>And she went on shrinking and growing, shedding gallons of tears, until there was a large pool around her.</p>
</body>
</html>''',
    });

    return _openEpubUseCase.fromBytes(zipBytes, bookId: 'sample_alice');
  }

  Uint8List _createZipBytes(Map<String, String> files) {
    final archive = Archive();
    files.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final encoder = ZipEncoder();
    return Uint8List.fromList(encoder.encode(archive)!);
  }
}
