class UaS_AlcoholTracker : Inventory {
    int intox;
    int mouth_intox;
    int pending_intox;
    float intox_quality;

    int jogged;
    bool drinking;

    default {
        +INVENTORY.PERSISTENTPOWER;
        +INVENTORY.UNTOSSABLE;
        -INVENTORY.INVBAR;
    }

    override void DoEffect() {
        if (owner.health <= 0) return;

        ProcessIntox();
    }

    void ProcessIntox() {
        HDPlayerPawn o = HDPlayerPawn(owner);
        if (!o) return;

        if (o.runwalksprint >= 0) jogged++;
        if (o.beatcount > 0) return;

        let intoxTokens = o.CountInv('UaSAlcohol_IntoxDrug');
        let addictTokens = o.CountInv('UaSAlcohol_AddictDrug');

        // Base Intox Drain
        if (intox > 0 && o.beatcounter % 2 == 0) {
            let burnoff = int(ceil(min(intox * frandom(0.001, 0.01), intox * frandom(0.001, 0.01))));

            if (hd_debug) console.printf("Burning off "..burnoff.." units of Intoxication");

            intox = max(intox - burnoff, -100);

            // Quality of Alcohol determines chances of addicition:
            // -100% -> 2x chance
            //    0% -> 1x chance
            // +100% -> 0x chance

            if (uas_alcohol_intox_effects & (1 << 11)) {
                if (hd_debug) console.printf('[UaS Alcohol] Addicition Enabled');
                let addictRatio = (2.0 - (intox_quality + 1.0));
                if ((random() * addictRatio) > burnoff) {
                    let newAddict = int(ceil(addictRatio));

                    if (hd_debug) console.printf("Gained a point of addiction, current: "..(addictTokens + newAddict));

                    o.GiveInventory('UaSAlcohol_AddictDrug', newAddict);
                }
            }
        }

        // Transfer Pending Intox
        if (pending_intox > 0 && o.beatcounter % 2 == 0) {
            let diffIntox = min(random(1, pending_intox * 0.5), random(1, pending_intox * 0.5));

            if (hd_debug) console.printf("Processing "..diffIntox.." units of intox from pending ("..pending_intox.."), current ("..intox..").");
            
            intox += diffIntox;
            pending_intox -= diffIntox;
        }

        // Sync up IntoxToken Counts
        let diffIntox = abs(intoxTokens - intox);
        if (intoxTokens < intox) o.GiveInventory('UaSAlcohol_IntoxDrug', diffIntox);
        else if (intoxTokens > intox) o.TakeInventory('UaSAlcohol_IntoxDrug', diffIntox);
    }

    void Consume(int addIntox = 0, float intoxQuality = 0.0) {

        // If we've disabled every effect, quit.
        if (!uas_alcohol_intox_effects) return;

        let currentIntox = pending_intox;

        if (hd_debug) console.printf("Comsuming "..addIntox.." units of intox...");
        
        // Add new amount of intox, then adjust the pending amount of quality of that intox by averaging it against what's already there.
        pending_intox += addIntox;
        intox_quality = ((intox_quality * currentIntox) + (addIntox * intoxQuality)) / pending_intox;
    }
}
