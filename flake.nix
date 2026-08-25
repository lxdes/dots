{
  description = "My Fedora Home Manager config";
  inputs = {

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      homeConfigurations.forda = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          hostProfile = "forda";
          homeManagerImpure = false;
        };
        modules = [
          ./hosts/forda
        ];
      };

      homeConfigurations.thinkfor = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          hostProfile = "thinkfor";
          homeManagerImpure = false;
        };
        modules = [
          ./hosts/thinkfor
        ];
      };

      homeConfigurations.vm = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          hostProfile = "vm";
          homeManagerImpure = false;
        };
        modules = [
          ./hosts/vm
        ];
      };

      homeConfigurations.generic = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          hostProfile = "generic";
          homeManagerImpure = true;
        };
        modules = [
          ./hosts/generic
        ];
      };
    };
}
