component "libxslt" do |pkg, settings, platform|
  pkg.version "1.1.37"
  pkg.sha256sum "6dbeb21aa8c938e6a39010901c0e84122bb87225b4af31f76feb4e3a5b138a5c"
  pkg.url "https://gitlab.gnome.org/GNOME/libxslt/-/archive/v#{pkg.get_version}/libxslt-v#{pkg.get_version}.tar.bz2"
  pkg.mirror "#{settings[:buildsources_url]}/libxslt-#{pkg.get_version}.tar.gz"

  pkg.build_requires "libxml2"

  if platform.is_aix?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH)"
  elsif platform.is_cross_compiled_linux?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):#{settings[:bindir]}"
    pkg.environment "CFLAGS", settings[:cflags]
    pkg.environment "LDFLAGS", settings[:ldflags]

    # libxslt is picky about manually specifying the build host
    build = "--build x86_64-linux-gnu"
    # don't depend on libgcrypto
    disable_crypto = "--without-crypto"
  elsif platform.is_solaris?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:#{settings[:bindir]}"
    pkg.environment "CFLAGS", settings[:cflags]
    pkg.environment "LDFLAGS", settings[:ldflags]
    # Configure on Solaris incorrectly passes flags to ld
    pkg.apply_patch 'resources/patches/libxslt/disable-version-script.patch'
    pkg.apply_patch 'resources/patches/libxslt/Update-missing-script-to-return-0.patch'
  elsif platform.is_macos?
    if platform.is_cross_compiled?
      pkg.environment 'CC', 'clang -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CC', 'clang -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  else
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  end

  pkg.configure do
    [
      'autoreconf -i',
      "./configure --prefix=#{settings[:prefix]} --docdir=/tmp --with-libxml-prefix=#{settings[:prefix]} --without-python #{settings[:host]} #{disable_crypto} #{build}"
    ]
  end

  pkg.build do
    ["#{platform[:make]} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"]
  end

  pkg.install do
    [
      "#{platform[:make]} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install",
      "rm -rf #{settings[:datadir]}/gtk-doc",
      "rm -rf #{settings[:datadir]}/doc/#{pkg.get_name}*"
    ]
  end

end
