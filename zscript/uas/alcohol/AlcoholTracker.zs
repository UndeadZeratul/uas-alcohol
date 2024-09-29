class UaS_AlcoholTracker : Inventory {
    int intox;
    int mouth_intox;
    int pending_intox;

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

        let intoxTokens = o.CountInv('UaSAlcohol_IntoxToken');
        let addictTokens = o.CountInv('UaSAlcohol_AddictDrug');

        // Base Intox Drain
        if (intox > 0 && o.beatcounter % 35 == 0) {
            let burnoff = min(random(1, intox), random(1, intox));

            if (hd_debug) console.printf("Burning off "..burnoff.." units of Intoxication");

            intox = max(intox - burnoff, -100);

            if (random() < burnoff) {
                if (hd_debug) console.printf("Gained a point of addiction, current: "..(addictTokens + 1));

                o.GiveInventory('UaSAlcohol_AddictDrug', 1);
            }
        }

        // Transfer Pending Intox
        if (pending_intox > 0 && o.beatcounter % 2 == 0) {
            let diffIntox = min(random(1, pending_intox * 0.5), random(1, pending_intox * 0.5));

            if (hd_debug) console.printf("Processing "..diffIntox.." units of intox from pending ("..pending_intox.."), current ("..intox..").");
            
            intox += diffIntox;
            pending_intox -= diffIntox;
        }

        let diffIntox = abs(intoxTokens - intox);
        if (intoxTokens < intox) o.GiveInventory('UaSAlcohol_IntoxToken', diffIntox);
        else if (intoxTokens > intox) o.TakeInventory('UaSAlcohol_IntoxToken', diffIntox);
    }

    void Consume(int addintox = 0) {
        if (hd_debug) console.printf("Comsuming "..addintox.." units of intox...");
        pending_intox += addintox;
    }
}
