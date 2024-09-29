// This is designed to work in tandem with the Alcohol handler and do what it cannot,
// This seems terrible to run two at once, so if anyone has any better ideas lmk - Cozi
class UaSAlcohol_IntoxDrug : HDDrug {

    enum IntoxAmounts {
        HDINTOX_BLACKOUT = 2000,
        HDINTOX_BLACKOUTTIME = 50,
    }

    // int healtiming;

    override void OnHeartbeat(hdplayerpawn hdp){
        if (amount < 1) return;
        
        // Instead of the usual amount loss, we're gonna tie this bitch to the alcohol token, makes it easier to keep them even. - Cozi
        amount = hdp.countinv("UasAlcohol_IntoxToken");

        if (hd_debug >= 4) console.printf("Handler: Drunk at about "..amount);

        // Stims flush out foreign bodies, including alcohol
        if (hdp.countinv("HDStim") > HDStim.HDSTIM_MAX) {
            hdp.TakeInventory("UasAlcohol_IntoxToken", 10);
        }

        if (hdp.fatigue >= (20 - (amount * 0.01))) {
            if (hd_debug) console.printf("\c[yellow]Stumbled!");

            hdp.strength -= (random(1, 2));
        } else {

            double ret = min(0.15, amount * 0.003);

            // You're gonna be stronger the drunker you are.
            if (hdp.strength < ret + 1) hdp.strength += (hdp.countinv("UasAlcohol_IntoxToken") * 0.0001);
        }

        // And less stunned!
        if (hdp.stunned > 0) {
            hdp.stunned -= (hdp.countinv("UasAlcohol_IntoxToken") * 0.00001);
            hdp.fatigue += 0.1;
        }
        
        // Positive Things!
        // Superhuman healing feels more BlueRum than everyday alcohol
        // if (healtiming == 8) { //super delay of healing
        //     hdp.burncount--;
        //     hdp.aggravateddamage--;
        //     healtiming = 0;
        // } else {
        //     healtiming++;
        // }

        hdp.bloodloss--;
    }
}

class UaSAlcohol_BlackoutDrug : HDDrug {

    override void DoEffect() {
        let hdp = HDPlayerPawn(owner);
        
        hdp.beatcap == 10;

        hdp.Disarm(hdp);
        hdp.A_SelectWeapon("HDIncapWeapon");
        
        hdp.incapacitated++;
        hdp.incaptimer = 10; //This is my hacky "stay down" fix, please don't mess with it - Cozi
        
        hdp.muzzleclimb1 += (0, frandom(8, 4));
        hdp.stunned++;
        
        hdp.AddBlackout(256, 2, 4, 24);
    }

    override void OnHeartbeat(HDPlayerPawn hdp) {
        if (amount < 1) return;

        amount--;
        
        if (hd_debug >= 4) {
            console.printf("Passed out for "..amount..", Intox Token: "..hdp.countinv("UasAlcohol_IntoxToken"));
        }
    }
}

// Addiction consumable class.
class UaSAlcohol_AddictDrug : HDDrug {

    override void OnHeartbeat(HDPlayerPawn hdp) {
        if (amount < 1) return;

        if (!hdp.countinv("UaSAlcohol_IntoxDrug")) {
            amount--;

            hdp.fatigue += 1;
            hdp.stunned += 2;
            
            if (hdp.beatcap < 30) hdp.beatcap++;

            if (hd_debug >= 4) console.printf("Going through withdrawals for "..amount);
        }
    }
}