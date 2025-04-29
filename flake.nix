{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Add the forked nix-bitcoin
    nix-bitcoin.url = "github:steepdawn974/nix-bitcoin/add-bitcoinknots";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nix01 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.stark84 = import ./home-manager/users/stark84.nix;
        }
        inputs.disko.nixosModules.disko
        inputs.nix-bitcoin.nixosModules.default
        ./configuration.nix
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
