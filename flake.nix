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

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    catppuccin.url = "github:catppuccin/nix";
    nix-flatpak.url = "github:in-a-dil-emma/declarative-flatpak/latest";
  };

  outputs =
    {
      agenix,
      catppuccin,
      home-manager,
      mac-app-util,
      nix-flatpak,
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
            home-manager.backupFileExtension = "bkp";
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
              agenix.homeManagerModules.default
            ];
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
