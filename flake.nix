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
      mkHost =
        host: impure:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            hostProfile = host;
            homeManagerImpure = impure;
          };
          modules = [
            ./hosts/${host}
          ];
        };
    in
    {
      homeConfigurations = {
        forda = mkHost "forda" false;
        thinkfor = mkHost "thinkfor" false;
        vm = mkHost "vm" false;
        generic = mkHost "generic" true;
      };
    };
}
