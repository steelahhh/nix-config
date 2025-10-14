{
  description = "Lazy way to do dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    mac-app-util.url = "github:hraban/mac-app-util";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    catppuccin.url = "github:catppuccin/nix";
    nix-flatpak.url = "github:in-a-dil-emma/declarative-flatpak/stable-v3";
  };

  outputs =
    {
      catppuccin,
      home-manager,
      mac-app-util,
      nix-flatpak,
      nix-homebrew,
      nixos-hardware,
      nixpkgs,
      ...
    }@inputs:
    {
      darwinConfigurations."ignis" = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = {
          self = inputs.self;
          inherit inputs;
        };
        modules = [
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              autoMigrate = true;
              mutableTaps = true;
              user = "Ignis";
              taps = with inputs; {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
            };
          }
          ./modules/darwin
          ./hosts/darwin
        ];
      };

      nixosConfigurations."ignis" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          self = inputs.self;
          inherit inputs;
        };
        modules = [
          nix-flatpak.nixosModule
          home-manager.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bkp";
          }
          nixos-hardware.nixosModules.lenovo-legion-16ach6h-nvidia
          ./hosts/nixos
          ./modules/nixos
        ];
      };
    };
}
