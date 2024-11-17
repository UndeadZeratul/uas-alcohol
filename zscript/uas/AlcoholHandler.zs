// Updated handler (3/26/22) for edge-case desyncs. Thanks Cali, Phantom, & FDA.

class UaS_AlcoholEventHandler : StaticEventHandler {
    override void WorldTick() {
        bool enableShader = false;

        if (playeringame[consoleplayer]) {
            PlayerInfo player = players[consoleplayer];
            Actor playerCam = player.mo;

            if(player.camera) playerCam = player.camera;

            if(playerCam) enableShader = playerCam.countInv("UasAlcohol_IntoxDrug") >= UaSAlcohol_IntoxDrug.min_effect_amt;

            IntoxShader.SetEnabled(player, enableShader);
        }
    }
}
