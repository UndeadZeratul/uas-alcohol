/**
* Base alcohol consumable class.
*/
class UaS_Alcohol : UaS_Consumable {
    int intox_per_bulk;
    property IntoxPerbulk:intox_per_bulk;
    
    UaS_AlcoholTracker intoxTracker;

    default {
        +UaS_Consumable.DRINKABLE

        UaS_Consumable.SpoilRate 0;
    }

    override void OnConsume() {
        HDPlayerPawn hdp = HDPlayerPawn(intoxTracker.owner);
        if (hdp) {
            ConsumeAlcohol();
        }
    }

    void ConsumeAlcohol() {
        if (intox_per_bulk <= 0) return;

        let intox = intox_per_bulk * diffBulk;

        if (hd_debug) console.printf("Consuming "..intox.." units of alcohol");

        intoxTracker.Consume(intox);
    }

    override void DoEffect() {
        if (!CriticalChecks()) return;
        if (!CriticalAlcoholChecks()) return;

        DoAlcoholMessage();
        HandleInput();
        CheckAutoDrop();
        SetHelpText();
    }

    bool CriticalAlcoholChecks() {
        // Set up tracker connection
        intoxTracker = UaS_AlcoholTracker(owner.FindInventory("UaS_AlcoholTracker"));
        if (!intoxTracker) { console.printf("no alcohol tracker!"); return false; }

        return true;
    }

    void DoAlcoholMessage() {
        string statusMessage;
        statusMessage.appendformat(DisplayDescription());
        statusMessage.appendformat(DisplayFoodlist());
        statusMessage.appendformat(DisplayIntox());
        statusMessage.appendformat(DisplayNutrition());
        statusMessage.appendformat(DisplayStatus());
        A_WeaponMessage(statusMessage);
    }

    string DisplayIntox() {
        string r;
        if (intox_per_bulk > 0) {
            r.appendformat(Stringtable.Localize("$UAS_ALCOHOL_DISPLAY_INTOX"), intox_per_bulk * 2);
        }
        return r;
    }
}