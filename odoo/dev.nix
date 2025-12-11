# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    $PACKAGES
  ];
  # Sets environment variables in the workspace
  env = { };
  services.postgres = {
    enable = true;
  };
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "ms-python.python"
    ];
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["sh" "httpserver.sh" "$PORT"];
          manager = "web";
        };
      };
    };
    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        odoo-install = ''
          python -m venv .venv
          ln -s /home/user/odoo17/.idx/.data/odoo/odoo-bin .venv/bin/odoo-bin
          source .venv/bin/activate
          OPENLDAP_DEV=$(nix eval --raw nixpkgs#openldap.dev.outPath)
CYRUS_DEV=$(nix eval --raw nixpkgs#cyrus_sasl.dev.outPath)
OPENSSL_DEV=$(nix eval --raw nixpkgs#openssl.dev.outPath)
OPENLDAP=$(nix eval --raw nixpkgs#openldap.outPath)
CYRUS=$(nix eval --raw nixpkgs#cyrus_sasl.outPath)

 # Compiler & linker hints: make python-ldap discover headers/libs
           export CPPFLAGS="-I/usr/include"
          export LDFLAGS="-L/usr/lib -L/usr/lib64"
          export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/lib64/pkgconfig"
          python -m pip install --upgrade pip setuptools wheel

          NIX_LDFLAGS="$NIX_LDFLAGS $LDFLAGS $CPPFLAGS -L$VIRTUAL_ENV/lib" pip install -r .idx/.data/odoo/requirements.txt
          odoo-bin --save --stop-after-init
          
          mv ../.odoorc odoo.conf
          mkdir -p /home/user/odoo/custom_addons
          sed -i                                                                 \
              -e "/^addons_path =/ s/\$/,\/home\/user\/odoo17\/custom_addons/" \
              -e "s/.local\/share\/Odoo/odoo17\/.idx\/.data\/odoo-data/g"      \
              odoo.conf
        '';
        # Open editors for the following files by default, if they exist:
        default.openFiles = [ "README.md" ];
      };
    };
  };
}