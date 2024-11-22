// This is designed to work in tandem with the Alcohol handler and do what it cannot,
// This seems terrible to run two at once, so if anyone has any better ideas lmk - Cozi
class UaSAlcohol_IntoxDrug : HDDrug {
    default {
        Inventory.Amount 1;
        Inventory.MaxAmount 100000;
    }

    // TODO: Refactor into CVARs

    const min_effect_amt = 3000;
    const max_effect_amt = 10000; // don't raise this or any shader effects higher than they are already
    const txshd_freq = 35; // blur radius change per heartbeat

    const min_sttr_chance = 0.005; // chance per heartbeat to stutter (random camera angle + pitch shift)
    const max_sttr_chance = 0.35;
    const angle_sttr = 1.05; // maximum angle/pitch shift when stuttering
    const pitch_sttr = 0.85;

    const min_move_chance = 0.001; // chance per heartbeat to randomly move
    const max_move_chance = 0.4;
    const move_amt = 2.1; // random movement velocity

    const min_drop_chance = 0.001; // chance per heartbeat to drop your current weapon
    const max_drop_chance = 0.005;

    const bpinc_min_chance = 0.07; // chance of blood pressure increasing every heartbeat
    const bpinc_max_chance = 0.7;
    const bp_max = 180; // maximum blood pressure

    const min_snd_chance = 0.002; // chance per heartbeat to emit a random sound (grunt/med/taunt)
    const max_snd_chance = 0.01;

    const hp_regen_threshold = 35;
    const hp_regen_min_chance = 0.1; // chance to regenerate 1 point of hp per heartbeat, if below hp regeneration threshold
    const hp_regen_max_chance = 0.55;

    const incap_regen_min = 0; // incap timer reduction per heartbeat (from 1x to 4x speed)
    const incap_regen_max = 3;

    const fatigue_regen_min = 0; // fatigue reduction per second
    const fatigue_regen_max = 2;

    const dmg_min_amt  = 3000;
    const dmg_max_amt  = 30000;
    const dmg_fact_min = 1.0;
    const dmg_fact_max = 0.4;

    const melee_dmg_fact_min = 1.35;
    const melee_dmg_fact_max = 3.75;


    const tox_heal_rate_min = 3; // intoxication heal rate, per second
    const tox_heal_rate_max = 7;

    const tox_blackout_threshold = 40000; // amount of intoxication before blacking out
    const tox_death_threshold = 50000;    // amount of intoxication before possible heart attack

    UaS_AlcoholTracker intoxTracker;

    // Shader stuff

    int txshd_minr;
    int txshd_maxr;
    int txshd_r;
    int txshd_dir;

    override void OnHeartbeat(HDPlayerPawn hdp) {
        super.OnHeartbeat(hdp);

        // let intox_perc = clamp(double(amount) / maxAmount, 0.0, 1.0);
        let effectRatio = (clamp(amount, min_effect_amt, max_effect_amt) - min_effect_amt) / (max_effect_amt - min_effect_amt);

        // Set up tracker connection
        intoxTracker = UaS_AlcoholTracker(hdp.FindInventory("UaS_AlcoholTracker"));
        if (!intoxTracker) {
            console.printf("no alcohol tracker!");
            return;
        }

        // Stim Interactions
        //------------------
        // Stims flush out foreign bodies, including alcohol
        // (the worse the quality, the more it flushes)

        if (hdp.countinv("HDStim")) {
            hdp.TakeInventory("HDStim", 4);
            hdp.TakeInventory("UasAlcohol_IntoxDrug", 5000 - (2000 * (intoxTracker.intox_quality + 1.0)));
        }

        // Adjust Player Strength
        if (uas_alcohol_intox_effects & (1 << 10)) {
            // The more drunk, the less fatigued you need to be to stumble
            if (hdp.fatigue >= (20 - (effectRatio * 10.0 * -(intoxTracker.intox_quality - 1.0)))) {

                // Temporary drop in strength
                hdp.strength -= random(1, 2);
            } else {

                // You're gonna be stronger the drunker you are.
                let strBonus = min(0.15, effectRatio * (intoxTracker.intox_quality + 1.0));
                if (hdp.strength < hdp.basestrength() + strBonus) {
                    hdp.strength += strBonus;
                }
            }
        }

        // ----------------
        // Negative effects
        // ----------------

        // Visual Degredation
        // ------------------
        // Looping between min and max blur shader radius

        if (uas_alcohol_intox_effects & (1 << 0)) {
            if (hd_debug) console.printf('[UaS Alcohol] Shaders Enabled');
            if (txshd_dir == 0) txshd_dir = 1;

            if (amount >= min_effect_amt) IntoxShader.Enable(hdp.player);
            else if (amount < min_effect_amt) IntoxShader.Disable(hdp.player);

            if (txshd_dir == 0) txshd_dir = 1;

            txshd_minr = effectRatio * 2;
            txshd_maxr = effectRatio * 7;

            if (Level.time % txshd_freq == 0) txshd_r += txshd_dir;

            if (txshd_r >= txshd_maxr) txshd_dir = -1;
            if (txshd_r <= txshd_minr) txshd_dir = 1;

            IntoxShader.SetRadius(hdp.player, txshd_r);
        } else {
            IntoxShader.Disable(hdp.player);
        }

        // Blood Pressure Increase
        // -----------------------
        if (uas_alcohol_intox_effects & (1 << 1)) {
            double bpinc_chance = bpinc_min_chance + (bpinc_max_chance - bpinc_min_chance) * effectRatio;
            if (hdp.bloodpressure <= bp_max && frandom(0.0, 1.0) < bpinc_chance) {
                hdp.bloodpressure += random(1, 10);
            }
        }

        // Black-out Intoxication
        // ----------------------
        // Passing out drunk? In my Hideous? More likely than you think...
        if (uas_alcohol_intox_effects & (1 << 2)) {
            let blackoutThreshold = tox_blackout_threshold + (tox_blackout_threshold * intoxTracker.intox_quality * 0.25);
            let currBlackout = hdp.CountInv('UaSAlcohol_BlackoutDrug');
            if (
                !currBlackout
                && tox_blackout_threshold > 0
                && amount > blackoutThreshold
                && !hdp.incapacitated
                && random(0, amount + (amount * -intoxTracker.intox_quality)) > blackoutThreshold
            ) {
                let blackoutMax = maxAmount - blackoutThreshold;
                let blackoutRatio = clamp(amount - blackoutThreshold, 0, blackoutMax) / blackoutMax;

                int blackoutAmt = amount * blackoutRatio;
                hdp.giveInventory("UaSAlcohol_BlackoutDrug", random(blackoutAmt >> 9, blackoutAmt >> 7));
            } else if (
                currBlackout
                && (tox_blackout_threshold <= 0 || amount < blackoutThreshold)
            ) {
                hdp.TakeInventory('UaSAlcohol_BlackoutDrug', currBlackout);
            }
        }

        // Lethal Blood Alcohol Level
        // --------------------------
        // Don't binge drink
        if (uas_alcohol_intox_effects & (1 << 3)) {
            let deathThreshold = tox_death_threshold + (tox_death_threshold * intoxTracker.intox_quality * 0.1);

            if (
                tox_death_threshold > 0
                && amount > deathThreshold
                && random(0, amount + (amount * -intoxTracker.intox_quality)) > deathThreshold
            ) {
                let deathMax = maxAmount - deathThreshold;
                let deathRatio = clamp(amount - deathThreshold, 0, deathMax) / deathMax;

                if (hdp.beatcap > max(6, 20 - (int(amount * deathRatio) >> 9))) hdp.beatcap -= random(5, 15);

                if (hdp.stunned < 10) hdp.stunned += 10;

                if (hdp.bloodpressure < (HDCONST_MAXBLOODLOSS - hdp.bloodloss)) hdp.bloodpressure += 20;
            }
        }

        // Stuttering and Moving
        // ---------------------
        // Crouching and being incapped no longer jitters you around,
        // bc this is simulating difficulty holding balance,
        // if you crouch or lay down, that's mitigated - [Cozi]
        if (uas_alcohol_intox_effects & (1 << 4)) {
            if (
                !(
                    amount < min_effect_amt
                    || hdp.Incapacitated > 0
                    || hdp.player.crouchfactor < 1
                )
            ) {
                double sttr_chance = min_sttr_chance + (max_sttr_chance - min_sttr_chance) * effectRatio;
                if (frandom(0.0, 1.0) < sttr_chance) {
                    hdp.angle += frandom(-angle_sttr, angle_sttr);
                    hdp.pitch += frandom(-pitch_sttr, pitch_sttr);
                }

                double move_chance = min_move_chance + (max_move_chance - min_move_chance) * effectRatio;
                if (frandom(0.0, 1.0) < move_chance) {
                    hdp.A_ChangeVelocity(frandom(-move_amt, move_amt), frandom(-move_amt, move_amt));
                }

                double drop_chance = min_drop_chance + (max_drop_chance - min_drop_chance) * effectRatio;
                if (frandom(0.0, 1.0) < drop_chance) {
                    HDPlayerPawn.Disarm(hdp);
                    hdp.A_SelectWeapon("HDFist");
                }
            }
        }

        // Making Sounds
        // -------------
        // Only make sounds if "phsyically capable" meaning you're not incapacitated or black-out drunk
        if (uas_alcohol_intox_effects & (1 << 5)) {
            double snd_chance = min_snd_chance + (max_snd_chance - min_snd_chance) * (effectRatio + (effectRatio * intoxTracker.intox_quality));
            if (!hdp.incapacitated && frandom(0.0, 1.0) < snd_chance) {
                int type = frandom(0, 7);
                if (type < 4) {
                    hdp.A_StartSound(hdp.gruntsound);
                } else if (type < 7) {
                    hdp.A_StartSound(hdp.medsound);
                } else {
                    EventHandler.SendNetworkEvent('hd_taunt');
                }
            }
        }

        // ----------------
        // Positive effects
        // ----------------

        // Increased Health Recovery?
        if (uas_alcohol_intox_effects & (1 << 6)) {
            if (hdp.health <= (hp_regen_threshold + (hp_regen_threshold * intoxTracker.intox_quality))) {
                double hp_regen_chance = hp_regen_min_chance + (hp_regen_max_chance - hp_regen_min_chance) * (effectRatio * (intoxTracker.intox_quality + 1.0));
                if (frandom(0.0, 1.0) < hp_regen_chance) hdp.giveInventory("Health", 1);
            }
        }

        // Reduced Incap
        if (uas_alcohol_intox_effects & (1 << 7)) {
            if (hdp.incaptimer > 1) {
                int incap_regen = incap_regen_min + (incap_regen_max - incap_regen_min) * (effectRatio * (intoxTracker.intox_quality + 1.0));
                hdp.incaptimer -= incap_regen;
            }
        }

        // And less stunned, at the cost of fatigue!
        if (uas_alcohol_intox_effects & (1 << 8)) {
            if (hdp.stunned > 0) {
                hdp.stunned -= max(1, (amount * 0.0001) * effectRatio * (intoxTracker.intox_quality + 1.0));
                hdp.fatigue += 0.1;
            }
        }

        // Increased Fatigue Recovery
        if (uas_alcohol_intox_effects & (1 << 9)) {
            if (hdp.fatigue > 0 && !(Level.time % TICRATE)) {
                int fatigue_regen = fatigue_regen_min + (fatigue_regen_max - fatigue_regen_min) * (effectRatio * (intoxTracker.intox_quality + 1.0));
                hdp.fatigue -= fatigue_regen;
            }
        }
    }
}

class UaSAlcohol_BlackoutDrug : HDDrug {

    override void OnHeartbeat(HDPlayerPawn hdp) {
        if (amount < 1) return;

        hdp.beatcap == 10;

        hdp.Disarm(hdp);
        hdp.A_SelectWeapon("HDIncapWeapon");

        hdp.incapacitated++;
        hdp.incaptimer = amount; //This is my hacky "stay down" fix, please don't mess with it - Cozi

        hdp.muzzleclimb1 += (0, frandom(8, 4));
        hdp.stunned++;

        hdp.AddBlackout(256, 2, 4, 24);

        amount--;

        if (hd_debug >= 4) console.printf("Passed out for "..amount..", IntoxDrug: "..hdp.countinv("UasAlcohol_IntoxDrug"));
    }
}

// Addiction consumable class.
class UaSAlcohol_AddictDrug : HDDrug {

    override void OnHeartbeat(HDPlayerPawn hdp) {
        if (amount < 1) return;

        if (!hdp.countinv("UaSAlcohol_IntoxDrug")) {
            amount -= int(round(min(frandom(0.0, 1.0), frandom(0.0, 0.1))));

            hdp.fatigue += 1;
            hdp.stunned += 2;

            if (hdp.beatcap < 30) hdp.beatcap++;

            if (hd_debug >= 4) console.printf("Going through withdrawals for "..amount);
        }
    }
}