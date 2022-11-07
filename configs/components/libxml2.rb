component "libxml2" do |pkg, settings, platform|
  pkg.version "2.10.3"
  pkg.sha256sum "302bbb86400b8505bebfbf7b3d1986e9aa05073198979f258eed4be481ff5f83"
  pkg.url "https://gitlab.gnome.org/GNOME/libxml2/-/archive/v#{pkg.get_version}/libxml2-v#{pkg.get_version}.tar.bz2"
  pkg.mirror "#{settings[:buildsources_url]}/libxml2-#{pkg.get_version}.tar.gz"

  if platform.is_aix?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH)"

    # https://github.com/GNOME/libxml2/commit/8813f397f8925f85ffbe9e9fb62bfaa3c1accf11
    # shows that libxml2 relies on the C99 macros NAN, INFINITY, isnan, isinf. If these
    # macros are not defined on the target machine (like on AIX), then libxml2 defines them.
    # Unfortunately on AIX, gcc cannot compile libxml2 with these macro definitions because
    # they're evaluated using non-constant expressions and then assigned to global variables.
    # The C-standard does not let one assign the value of a non-constant expression to a global
    # variable. Fortunately, https://mail.gnome.org/archives/xml/2018-March/msg00003.html provides
    # a patch for this issue, which is what we use here.
    pkg.apply_patch "resources/patches/libxml2/aix_non_constant_initializer.patch"
  elsif platform.is_cross_compiled_linux?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):#{settings[:bindir]}"
    pkg.environment "CFLAGS", settings[:cflags]
    pkg.environment "LDFLAGS", settings[:ldflags]
  elsif platform.is_solaris?
    pkg.environment "PATH", "/opt/pl-build-tools/bin:$(PATH):/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:#{settings[:bindir]}"
    pkg.environment "CFLAGS", "#{settings[:cflags]} -std=c99"
    pkg.environment "LDFLAGS", settings[:ldflags]
  elsif platform.is_macos?
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
    if platform.is_cross_compiled?
      pkg.environment 'CC', 'clang -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CC', 'clang -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end
  else
    pkg.environment "LDFLAGS", settings[:ldflags]
    pkg.environment "CFLAGS", settings[:cflags]
  end

  pkg.build_requires "runtime-#{settings[:runtime_project]}"
  build_requires 'autoconf libgcrypt20 libgcrypt20-dev libtool make pkg-config'

  pkg.configure do
    [
      'autoreconf -i',
      "./configure --prefix=#{settings[:prefix]} --without-python #{settings[:host]}"
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
