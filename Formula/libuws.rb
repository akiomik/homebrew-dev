class Libuws < Formula
  desc "Simple, secure & standards compliant web server for the most demanding of applications"
  homepage "https://github.com/uNetworking/uWebSockets"
  url "https://github.com/uNetworking/uWebSockets/archive/refs/tags/v20.74.0.tar.gz"
  sha256 "e1d9c99b8e87e78a9aaa89ca3ebaa450ef0ba22304d24978bb108777db73676c"
  license "Apache-2.0"
  head "https://github.com/uNetworking/uWebSockets.git", branch: "master"

  depends_on "openssl@3" unless ENV["HOMEBREW_LIBUWS_WITHOUT_OPENSSL"]
  depends_on "pkg-config" => :build

  # uSockets dependency - using specific revision for v20.74.0 compatibility
  resource "usockets" do
    url "https://github.com/uNetworking/uSockets.git", revision: "182b7e4fe7211f98682772be3df89c71dc4884fa"
  end

  def install
    # Check if OpenSSL support is enabled
    use_openssl = !ENV["HOMEBREW_LIBUWS_WITHOUT_OPENSSL"]

    # Handle uSockets dependency (normally a git submodule)
    unless (buildpath/"uSockets").exist?
      resource("usockets").stage(buildpath/"uSockets")
    end

    # Build uSockets as a static library
    cd "uSockets" do
      if use_openssl
        # Use Homebrew's standard environment setup for OpenSSL
        ENV.append_to_cflags "-I#{Formula["openssl@3"].opt_include}"
        ENV.append "LDFLAGS", "-L#{Formula["openssl@3"].opt_lib}"

        system "make", "clean"
        system "make", "WITH_OPENSSL=1"
      else
        system "make", "clean"
        system "make"
      end

      # Verify static library was created
      odie "Failed to build uSockets static library" unless (buildpath/"uSockets/uSockets.a").exist?
    end

    # Create dynamic library wrapper
    (buildpath/"dylib_wrapper.cpp").write <<~EOS
      #include "src/App.h"

      // Export version and capability information
      extern "C" {
          const char* uws_version() {
              return "#{version}";
          }

          int uws_init() {
              return 1;
          }

          int uws_ssl_available() {
              return #{use_openssl ? 1 : 0};  // SSL support based on build option
          }
      }

      // Force template instantiation for common types to ensure they're available
      namespace uWS {
          // Instantiate non-SSL App types (always available)
          template class TemplatedApp<false>;  // uWS::App
          template class HttpResponse<false>;  // HTTP responses

          #{use_openssl ? '// Instantiate SSL App types (when OpenSSL is enabled)
          template class TemplatedApp<true>;   // uWS::SSLApp
          template class HttpResponse<true>;   // HTTPS responses' : '// SSL types not available without OpenSSL'}

          // Force instantiation for WebSockets
          void force_instantiation() {
              // This forces compilation of WebSocket templates
              static_cast<void>(sizeof(WebSocket<false, true, int>));
              #{use_openssl ? 'static_cast<void>(sizeof(WebSocket<true, true, int>));' : '// SSL WebSockets not available'}
          }
      }
    EOS

    # Extract object files from uSockets static library
    (buildpath/"objects").mkdir
    cd "objects" do
      system "ar", "x", "../uSockets/uSockets.a"
    end

    # Configure compilation flags based on OpenSSL support
    if use_openssl
      openssl = Formula["openssl@3"]
      openssl_cflags = "-I#{openssl.opt_include}"
      openssl_libs = "-L#{openssl.opt_lib} -lssl -lcrypto"
      ssl_defines = "-DLIBUS_USE_OPENSSL"
    else
      openssl_cflags = ""
      openssl_libs = ""
      ssl_defines = ""
    end

    # Compile the wrapper with position independent code
    system ENV.cxx, "-std=c++17", "-fPIC", "-O3", "-DNDEBUG",
           openssl_cflags,
           "-Isrc", "-IuSockets/src",
           ssl_defines,
           "-c", "dylib_wrapper.cpp", "-o", "dylib_wrapper.o"

    # Create the dynamic library with proper macOS naming conventions
    dylib_version = version.to_s
    dylib_name = shared_library("libuWS", dylib_version)

    # Link the dynamic library
    link_args = [ENV.cxx, "-shared", "-fPIC",
                 "-o", dylib_name,
                 "dylib_wrapper.o", *Dir["objects/*.o"],
                 "-lz",
                 "-install_name", "#{lib}/#{shared_library("libuWS")}",
                 "-compatibility_version", version.major_minor,
                 "-current_version", dylib_version]

    # Add OpenSSL libraries only if enabled
    link_args.insert(-6, *openssl_libs.split) if use_openssl

    system(*link_args)

    # Install the library with proper symlinks using Homebrew helpers
    lib.install dylib_name
    lib.install_symlink dylib_name => shared_library("libuWS")
    lib.install_symlink dylib_name => shared_library("libuWS", version.major)

    # Install headers in the standard layout
    include.install "src" => "uWebSockets"
    include.install "uSockets/src" => "uSockets"

    # Create comprehensive pkg-config file
    (lib/"pkgconfig").mkpath
    pkg_config_content = <<~EOS
      prefix=#{prefix}
      exec_prefix=${prefix}
      libdir=#{lib}
      includedir=#{include}

      Name: libuws
      Description: Simple, secure & standards compliant web server#{use_openssl ? " with SSL support" : " (without SSL)"}
      URL: #{homepage}
      Version: #{version}
      #{use_openssl ? "Requires: openssl >= 1.1.0" : "# No SSL dependencies"}
      Libs: -L${libdir} -luWS
      Libs.private: -lz#{use_openssl ? " -lssl -lcrypto" : ""}
      Cflags: -I${includedir}/uWebSockets -I${includedir}/uSockets#{use_openssl ? " -DLIBUS_USE_OPENSSL" : ""}
    EOS
    (lib/"pkgconfig/uWebSockets.pc").write pkg_config_content

    # Install documentation and examples using Homebrew paths
    doc.install "README.md" if (buildpath/"README.md").exist?
    doc.install Dir["misc/*.md"] if (buildpath/"misc").exist?

    # Install examples for reference
    if (buildpath/"examples").exist?
      pkgshare.install "examples"
    end
  end

  test do
    # Create a comprehensive test program
    (testpath/"test.cpp").write <<~EOS
      #include <uWebSockets/App.h>
      #include <iostream>
      #include <cassert>

      extern "C" {
          const char* uws_version();
          int uws_init();
          int uws_ssl_available();
      }

      int main() {
          std::cout << "Testing uWebSockets #{version}..." << std::endl;

          // Test exported C functions
          std::cout << "Version: " << uws_version() << std::endl;
          assert(uws_init() == 1);
          std::cout << "SSL Support: " << (uws_ssl_available() ? "enabled" : "disabled") << std::endl;

          try {
              // Test HTTP app creation
              auto app = uWS::App().get("/test", [](auto *res, auto *req) {
                  res->end("HTTP OK");
              });
              std::cout << "✅ HTTP App creation successful" << std::endl;

              #{use_openssl ? '// Test SSL app creation (without actual certificates)
              uWS::SocketContextOptions ssl_options = {};
              auto sslApp = uWS::SSLApp(ssl_options).get("/test", [](auto *res, auto *req) {
                  res->end("HTTPS OK");
              });
              std::cout << "✅ SSL App creation successful" << std::endl;' : '// SSL App tests skipped (SSL not enabled)
              std::cout << "ℹ️ SSL App tests skipped (not compiled with SSL support)" << std::endl;'}

              // Test WebSocket configuration
              app.ws<int>("/*", {
                  .open = [](auto *ws) {
                      // WebSocket opened
                  },
                  .message = [](auto *ws, std::string_view message, uWS::OpCode opCode) {
                      ws->send(message, opCode);
                  }
              });
              std::cout << "✅ WebSocket configuration successful" << std::endl;

              std::cout << "🎉 All tests passed!" << std::endl;
              return 0;
          } catch (const std::exception& e) {
              std::cerr << "❌ Test failed: " << e.what() << std::endl;
              return 1;
          }
      }
    EOS

    # Test compilation and execution using Homebrew standard methods
    use_openssl = !ENV["HOMEBREW_LIBUWS_WITHOUT_OPENSSL"]

    # Test with pkg-config using Homebrew environment helpers
    with_env(PKG_CONFIG_PATH: "#{lib}/pkgconfig:#{ENV["PKG_CONFIG_PATH"]}") do
      if which("pkg-config")
        cflags = shell_output("pkg-config --cflags uWebSockets").chomp
        libs = shell_output("pkg-config --libs uWebSockets").chomp

        test_args = [ENV.cxx, "-std=c++17", *cflags.split, "test.cpp", *libs.split, "-lz", "-o", "test"]
        if use_openssl
          openssl = Formula["openssl@3"]
          test_args.insert(-3, "-L#{openssl.opt_lib}", "-lssl", "-lcrypto")
        end

        system(*test_args)
        system "./test"
      end
    end

    # Test manual compilation (fallback method)
    manual_args = [ENV.cxx, "-std=c++17",
                   "-I#{include}/uWebSockets", "-I#{include}/uSockets"]

    if use_openssl
      openssl = Formula["openssl@3"]
      manual_args += ["-DLIBUS_USE_OPENSSL", "-I#{openssl.opt_include}"]
    end

    manual_args += ["test.cpp", "-L#{lib}", "-luWS", "-lz"]

    if use_openssl
      manual_args += ["-L#{openssl.opt_lib}", "-lssl", "-lcrypto"]
    end

    manual_args += ["-o", "test_manual"]

    system(*manual_args)
    system "./test_manual"
  end
end
