class Libxml2 < Formula
  desc "GNOME XML library"
  homepage "http://xmlsoft.org"
  url "http://xmlsoft.org/sources/libxml2-2.9.3.tar.gz"
  mirror "ftp://xmlsoft.org/libxml2/libxml2-2.9.3.tar.gz"
  sha256 "4de9e31f46b44d34871c22f54bfc54398ef124d6f7cafb1f4a5958fbcd3ba12d"
  revision 1 unless OS.mac?

  bottle do
    cellar :any
    sha256 "543d5ad733130bca7640900cd04cce0d499d6eb858ec2d17a0cd49b428b4c8d1" => :el_capitan
    sha256 "3df0a8327d236e67e77075f108702e444169321716c430380ef99f93f6d7bc32" => :yosemite
    sha256 "87ec20eb4dc74d17f6fa1b9ef2f14bbf08449457e08fd061411c7504b609c2f0" => :mavericks
    sha256 "8e415d56bc5da40e18d908ab9c3f6929a89367c326d8cd4be8d8a6abe6868f40" => :x86_64_linux
  end

  head do
    url "https://git.gnome.org/browse/libxml2.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on :python => :optional
  depends_on "zlib" => :recommended unless OS.mac?

  keg_only :provided_by_osx

  option :universal

  fails_with :llvm do
    build 2326
    cause "Undefined symbols when linking"
  end

  def install
    ENV.universal_binary if build.universal?
    if build.head?
      inreplace "autogen.sh", "libtoolize", "glibtoolize"
      system "./autogen.sh"
    end

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--without-python",
                          "--without-lzma"
    system "make"
    ENV.deparallelize
    system "make", "install"

    if build.with? "python"
      cd "python" do
        # We need to insert our include dir first
        inreplace "setup.py", "includes_dir = [",
          "includes_dir = ['#{include}', '#{OS.mac? ? MacOS.sdk_path/"usr" : HOMEBREW_PREFIX}/include',"
        system "python", "setup.py", "install", "--prefix=#{prefix}"
      end
    end
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <libxml/tree.h>

      int main()
      {
        xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");
        xmlNodePtr root_node = xmlNewNode(NULL, BAD_CAST "root");
        xmlDocSetRootElement(doc, root_node);
        xmlFreeDoc(doc);
        return 0;
      }
    EOS
    args = %w[test.c -o test] + `#{bin}/xml2-config --cflags --libs`.split
    system ENV.cc, *args
    system "./test"
  end
end
