//
//  Colormanager.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI

struct Colormanager {
    static let baseBackground: Color = Color("background")
    static let secondaryBg: Color = Color("secondaryBackground")
    static let card: Color = Color("card")
    static let disbled: Color = Color("disabled")
    static let border: Color = Color("border")

    struct Accent {
        static let primary: Color = Color("primaryAccent")
        static let button: Color = Color("button")
        static let progressBar: Color = Color("progressBar")
        static let selected: Color = Color("selected")
    }

    struct Water {
        static let skyBlue: Color = Color("waterSkyBlue")
        static let lightBlue: Color = Color("waterLightBlue")
        static let deepBlue: Color = Color("waterDeepBlue")
    }

    struct Diet {
        static let softPeach: Color = Color("dietSoftPeach")
        static let apricot: Color = Color("dietApricot")
        static let cream: Color = Color("dietCream")
    }

    struct Workout {
        static let terracotta: Color = Color("workoutTerracotta")
        static let clay: Color = Color("workoutClay")
        static let sand: Color = Color("workoutSand")
    }

    struct MenstrualCycle {
        static let dustyRose: Color = Color("menstrualCycleDustyRose")
        static let blush: Color = Color("menstrualCycleBlush")
        static let mauve: Color = Color("menstrualCycleMauve")
    }

    struct Sleep {
        static let lavender: Color = Color("sleepLavender")
        static let periwinkle: Color = Color("sleepPeriwinkle")
        static let softPurple: Color = Color("sleepSoftPurple")
    }

    struct Notes {
        static let warmYellow: Color = Color("notesWarmYellow")
        static let vanilla: Color = Color("notesVanilla")
        static let honey: Color = Color("notesHoney")
    }

    struct Calendar {
        static let softMint: Color = Color("calendarSoftMint")
        static let mint: Color = Color("calendarMint")
        static let green: Color = Color("calendarGreen")
    }

    struct Typography {
        static let primaryText: Color = Color("typographyPrimaryText")
        static let secondaryText: Color = Color("typographySecondaryText")
        static let tertiaryText: Color = Color("typographyTertiaryText")
        static let placeholder: Color = Color("typographyPlaceholder")
    }

    struct Surfaces {
        static let background: Color = Color("surfacesBackground")
        static let card: Color = Color("surfacesCard")
        static let secondaryCard: Color = Color("surfacesSecondaryCard")
        static let border: Color = Color("surfacesBorder")
		static let logoColor: Color = Color("Logo-color")
    }

    struct Status {
        static let success: Color = Color("statusSuccess")
        static let warning: Color = Color("statusWarning")
        static let error: Color = Color("statusError")
        static let info: Color = Color("statusInfo")
    }

}
