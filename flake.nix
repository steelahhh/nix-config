{
  description = "Lazy way to do dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    # no nixpkgs follows, so numtide's binary cache matches
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      agenix,
      catppuccin,
      helium-flake,
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
          {
            nixpkgs.overlays = [ helium-flake.overlays.default ];
          }
          nix-flatpak.nixosModules.default
          home-manager.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bkp";
            home-manager.sharedModules = [ agenix.homeManagerModules.default ];
          }
          nixos-hardware.nixosModules.lenovo-legion-16ach6h-nvidia
          ./hosts/nixos
          ./modules/nixos
        ];
      };

      nixosConfigurations."homeserver" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          agenix.nixosModules.default
          ./hosts/homeserver
        ];
      };
    };
}
