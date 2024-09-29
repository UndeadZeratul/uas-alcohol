class UaS_Alcohol_Bootstrap : EventHandler {
    override void WorldTick() {
        for (int i = 0; i < MAXPLAYERS; i++) {
            if (!playeringame[i]) continue;
            PlayerInfo p = players[i];
            if (!p.mo) return;
            if (!p.mo.countinv("UaS_AlcoholTracker")) p.mo.giveinventory("UaS_AlcoholTracker", 1);
        }
    }
}
