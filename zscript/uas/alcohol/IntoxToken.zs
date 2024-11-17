// Intoxication code from cyb3r_c001's UaS Deus Ex pack.
// Just here for backwards Compatibility

class UaSAlcohol_IntoxToken : UaSAlcohol_IntoxDrug {

	override void DoEffect() {
		owner.GiveInventory('UaSAlcohol_IntoxDrug', amount);
		destroy();
	}
}