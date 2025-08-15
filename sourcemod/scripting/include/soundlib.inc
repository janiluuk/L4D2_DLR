#if defined _soundlib_included
 #endinput
#endif
#define _soundlib_included

/**
 * Minimal stub of Adrianilloo's soundlib include.
 * This provides just enough of the API for compilation.
 * The real implementation is required at runtime:
 * https://github.com/Adrianilloo/soundlib
 */

methodmap SoundFile < Handle {
    public SoundFile(const char[] path) {
        return view_as<SoundFile>(INVALID_HANDLE);
    }

    property float LengthFloat {
        public get() { return 0.0; }
    }
};

/**
 * Attempts to determine the length of a sound file.
 * Returns true on success and stores the length in seconds.
 */
bool IsValidGetSoundLength(const char[] sound, float &length) {
    length = 0.0;
    return false;
}

