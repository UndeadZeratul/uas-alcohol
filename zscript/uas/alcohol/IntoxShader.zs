class IntoxShader {
    static void Init(PlayerInfo pl) {
        let w = CVar.getCVar("menu_resolution_custom_width", pl).GetInt();
        let h = CVar.getCVar("menu_resolution_custom_height", pl).GetInt();

        IntoxShader.SetWidth(pl, w);
        IntoxShader.SetHeight(pl, h);
    }
    
    static void Reset(PlayerInfo pl) {
        IntoxShader.Init(pl);
        IntoxShader.SetRadius(pl, 1);
    }

    static void SetWidth(PlayerInfo pl, int w) {
        Shader.SetUniform1i(pl, "UASAlcohol_Intoxication", "res_w", w);
    }

    static void SetHeight(PlayerInfo pl, int h) {
        Shader.SetUniform1i(pl, "UASAlcohol_Intoxication", "res_h", h);
    }

    static void SetRadius(PlayerInfo pl, int r) {
        Shader.SetUniform1i(pl, "UASAlcohol_Intoxication", "radius", r);
    }

    static void Enable(PlayerInfo pl) {
        IntoxShader.Init(pl);
        Shader.SetEnabled(pl, "UASAlcohol_Intoxication", true);
    }
    
    static void Disable(PlayerInfo pl) {
        Shader.SetEnabled(pl, "UASAlcohol_Intoxication", false);
    }

    static void SetEnabled(PlayerInfo pl, bool enabled) {
        if (enabled) {
            IntoxShader.Enable(pl);
        } else {
            IntoxShader.Disable(pl);
        }
    }
}
