// Intoxication code from cyb3r_c001's UaS Deus Ex pack.

class UaSAlcohol_IntoxToken : Inventory
{
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 2500; // lasts 3 minutes at max
	}

	const min_effect_amt = 300;
	const max_effect_amt = 2500; // don't raise this or any shader effects higher than they are already
	const txshd_freq = 35; // blur radius change per tick

	const min_sttr_chance = 0.0005; // chance per tick to stutter (random camera angle + pitch shift)
	const max_sttr_chance = 0.035;
	const angle_sttr = 1.05; // maximum angle/pitch shift when stuttering
	const pitch_sttr = 0.85;

	const min_move_chance = 0.0001; // chance per tick to randomly move
	const max_move_chance = 0.04;
	const move_amt = 2.1; // random movement velocity

	const bpinc_min_chance = 0.007; // chance of blood pressure increasing by 1 every tick
	const bpinc_max_chance = 0.07; // chance of blood pressure increasing by 1 every tick
	const bp_max = 180; // maximum blood pressure

	const min_snd_chance = 0.0002; // chance per tick to emit a random sound (grunt/med/taunt)
	const max_snd_chance = 0.001;


	const hp_regen_threshold = 35;
	const hp_regen_min_chance = 0.01; // chance to regenerate 1 point of hp per tick, if below hp regeneration threshold
	const hp_regen_max_chance = 0.055;

	const incap_regen_min = 0; // incap timer reduction per tick (from 1x to 4x speed)
	const incap_regen_max = 3;

	const fatigue_regen_min = 0;
	const fatigue_regen_max = 2; // fatigue reduction per second

	const dmg_fact_min = 1.0;
	const dmg_fact_max = 0.4;

	const melee_dmg_fact_min = 1.35;
	const melee_dmg_fact_max = 3.75;


	const tox_heal_rate_max = 7; // intoxication heal rate, per second
	const tox_heal_rate_min = 3;

	const tox_blackout_threshold = 2000; // amount of intoxication before blacking out

	UaS_AlcoholTracker intoxTracker;

	// Shader stuff

	int txshd_minr;
	int txshd_maxr;
	int txshd_r;
	int txshd_dir;

	override void Tick()
	{
		super.tick();

		if(!owner || !(owner is "HDPlayerPawn")) return;

		double intox_perc = double(self.amount) / max_effect_amt;
		HDPlayerPawn hdp = HDPlayerPawn(owner);

		// Set up tracker connection
		intoxTracker = UaS_AlcoholTracker(owner.FindInventory("UaS_AlcoholTracker"));
		if (!intoxTracker) {
			console.printf("no alcohol tracker!");
			return;
		}

		// ----------------
		// Negative effects
		// ----------------

		// Looping between min and max blur shader radius

		if (txshd_dir == 0) txshd_dir = 1;

		if (amount >= min_effect_amt) IntoxShader.Enable(owner.player);
		else if (amount < min_effect_amt) IntoxShader.Disable(owner.player);

		if (txshd_dir == 0) txshd_dir = 1;

		txshd_minr = intox_perc * 2;
		txshd_maxr = intox_perc * 7;

		if (Level.time % txshd_freq == 0) txshd_r += txshd_dir;

		if (txshd_r >= txshd_maxr) txshd_dir = -1;
		if (txshd_r <= txshd_minr) txshd_dir = 1;
		
		IntoxShader.SetRadius(owner.player, txshd_r);

		// Blood pressure increase

		double bpinc_chance = bpinc_min_chance + (bpinc_max_chance - bpinc_min_chance) * intox_perc;
		if (hdp.bloodpressure <= bp_max && frandom(0.0, 1.0) < bpinc_chance) {
			hdp.bloodpressure++;
		}

		// Black-out Intoxication

		// Passing out drunk? In my Hideous? More likely than you think...
		if (
			!hdp.CountInv('UaSAlcohol_BlackoutDrug')
			&& tox_blackout_threshold > 0
			&& amount > tox_blackout_threshold
			&& !hdp.incapacitated
		) {
			hdp.giveInventory("UaSAlcohol_BlackoutDrug", random(30, amount - tox_blackout_threshold));
		}

		// Stuttering and moving

		// Crouching and being incapped no longer jitters you around,
		// bc this is simulating difficulty holding balance,
		// if you crouch or lay down, that's mitigated - [Cozi]
		if (
			!(
				amount < min_effect_amt
				|| hdp.Incapacitated > 0
				|| hdp.player.crouchfactor < 1
			)
		) {
			double sttr_chance = min_sttr_chance + (max_sttr_chance - min_sttr_chance) * intox_perc;
			if (frandom(0.0, 1.0) < sttr_chance) {
				owner.angle += frandom(-angle_sttr, angle_sttr);
				owner.pitch += frandom(-pitch_sttr, pitch_sttr);
			}

			double move_chance = min_move_chance + (max_move_chance - min_move_chance) * intox_perc;
			if (frandom(0.0, 1.0) < move_chance) {
				owner.A_ChangeVelocity(frandom(-move_amt, move_amt), frandom(-move_amt, move_amt));
			}
		}


		// Making sounds

		// Only make sounds if "phsyically capable" meaning you're not incapacitated or black-out drunk
		double snd_chance = min_snd_chance + (max_snd_chance - min_snd_chance) * intox_perc;
		if(!hdp.incapacitated && frandom(0.0, 1.0) < snd_chance)
		{
			int type = frandom(0, 7);
			if(type < 4)
				owner.A_StartSound(hdp.gruntsound);
			else if(type < 7)
				owner.A_StartSound(hdp.medsound);
			else
				EventHandler.SendNetworkEvent('hd_taunt');
		}

		// ----------------
		// Positive effects
		// ----------------

		if(hdp.health <= hp_regen_threshold)
		{
			double hp_regen_chance = hp_regen_min_chance + (hp_regen_max_chance - hp_regen_min_chance) * intox_perc;
			if(frandom(0.0, 1.0) < hp_regen_chance)
				hdp.giveInventory("Health", 1);
		}

		if(hdp.incaptimer > 1)
		{
			int incap_regen = incap_regen_min + (incap_regen_max - incap_regen_min) * intox_perc;
			hdp.incaptimer -= incap_regen;
		}

		if(hdp.fatigue > 0 && !(Level.time % TICRATE))
		{
			int fatigue_regen = fatigue_regen_min + (fatigue_regen_max - fatigue_regen_min) * intox_perc;
			hdp.fatigue -= fatigue_regen;
		}
	}

	override void ModifyDamage(int damage, Name damageType, out int newDamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		if(passive)
		{
			double intox_perc = double(self.amount) / max_effect_amt;

			double dmgfact = dmg_fact_min - (dmg_fact_min - dmg_fact_max) * intox_perc;
			double newdmg = damage * dmgfact;
			if(newdmg < 1 && damage > 1)
				newdmg = 1.0;
			newDamage = newdmg;
		}
		else if(owner && owner.player.readyWeapon && owner.player.readyWeapon is "HDFist")
		{
			double intox_perc = double(self.amount) / max_effect_amt;

			double melee_dmgfact = melee_dmg_fact_min - (melee_dmg_fact_min - melee_dmg_fact_max) * intox_perc;
			newDamage = damage * melee_dmgfact;
		}
	}
}
