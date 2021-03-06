class Hunspell < Formula
  desc "Spell checker and morphological analyzer"
  homepage "http://hunspell.sourceforge.net/"
  url "https://downloads.sourceforge.net/hunspell/hunspell-1.3.3.tar.gz"
  sha256 "a7b2c0de0e2ce17426821dc1ac8eb115029959b3ada9d80a81739fa19373246c"

  bottle do
    sha256 "cafeaa28d6684e743f52094975f46b962316c2263520d20e013606e2fac49f60" => :el_capitan
    sha256 "b43f5e8e6588fef04b7201c7b9998f88d45118132306c09adad09fbaa394ba33" => :yosemite
    sha256 "88afd83f16058a5a0ca55eb30469f7cebbb61c479e681c8d41195be3356da5cd" => :mavericks
    sha256 "3a1b824096746a4d4f88ae2f8cf11d930a25caaab97024818047be42ce66cb66" => :x86_64_linux
  end

  depends_on "readline"

  conflicts_with "freeling", :because => "both install 'analyze' binary"

  # hunspell does not prepend $HOME to all USEROODIRs
  # https://sourceforge.net/p/hunspell/bugs/236/
  patch :p0, :DATA

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-ui",
                          "--with-readline"
    system "make"
    ENV.deparallelize
    system "make", "install"

    pkgshare.install "tests"
  end

  def caveats; <<-EOS.undent
    Dictionary files (*.aff and *.dic) should be placed in
    ~/Library/Spelling/ or /Library/Spelling/.  Homebrew itself
    provides no dictionaries for Hunspell, but you can download
    compatible dictionaries from other sources, such as
    https://wiki.openoffice.org/wiki/Dictionaries .
    EOS
  end

  test do
    cp_r "#{pkgshare}/tests/.", testpath
    system "./test.sh"
  end
end

__END__
--- src/tools/hunspell.cxx.old	2013-08-02 18:21:49.000000000 +0200
+++ src/tools/hunspell.cxx	2013-08-02 18:20:27.000000000 +0200
@@ -28,7 +28,7 @@
 #ifdef WIN32

 #define LIBDIR "C:\\Hunspell\\"
-#define USEROOODIR "Application Data\\OpenOffice.org 2\\user\\wordbook"
+#define USEROOODIR { "Application Data\\OpenOffice.org 2\\user\\wordbook" }
 #define OOODIR \
     "C:\\Program files\\OpenOffice.org 2.4\\share\\dict\\ooo\\;" \
     "C:\\Program files\\OpenOffice.org 2.3\\share\\dict\\ooo\\;" \
@@ -65,11 +65,11 @@
     "/usr/share/myspell:" \
     "/usr/share/myspell/dicts:" \
     "/Library/Spelling"
-#define USEROOODIR \
-    ".openoffice.org/3/user/wordbook:" \
-    ".openoffice.org2/user/wordbook:" \
-    ".openoffice.org2.0/user/wordbook:" \
-    "Library/Spelling"
+#define USEROOODIR { \
+    ".openoffice.org/3/user/wordbook:", \
+    ".openoffice.org2/user/wordbook:", \
+    ".openoffice.org2.0/user/wordbook:", \
+    "Library/Spelling" }
 #define OOODIR \
     "/opt/openoffice.org/basis3.0/share/dict/ooo:" \
     "/usr/lib/openoffice.org/basis3.0/share/dict/ooo:" \
@@ -1664,7 +1664,10 @@
 	path = add(path, PATHSEP);          // <- check path in root directory
 	if (getenv("DICPATH")) path = add(add(path, getenv("DICPATH")), PATHSEP);
 	path = add(add(path, LIBDIR), PATHSEP);
-	if (HOME) path = add(add(add(add(path, HOME), DIRSEP), USEROOODIR), PATHSEP);
+  const char* userooodir[] = USEROOODIR;
+  for (int i = 0; i < (sizeof(userooodir) / sizeof(userooodir[0])); i++) {
+    if (HOME) path = add(add(add(add(path, HOME), DIRSEP), userooodir[i]), PATHSEP);
+  }
 	path = add(path, OOODIR);

 	if (showpath) {
