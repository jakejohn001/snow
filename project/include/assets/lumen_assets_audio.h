#ifndef _LUMEN_ASSETS_AUDIO_
#define _LUMEN_ASSETS_AUDIO_

#include <string>

#include "common/Object.h"
#include "common/QuickVec.h"

#include "lumen_io.h"

#include "libs/vorbis/vorbisfile.h"

namespace lumen {	

		//forward
	class OGG_file_source;

		//function declarations
	bool audio_load_ogg_info( QuickVec<unsigned char> &out_buffer, const char* _id, OGG_file_source*& ogg_source, bool read );
	long audio_read_ogg_data( OGG_file_source* ogg_source, QuickVec<unsigned char> &out_buffer, long start, long len, bool loop );
	bool audio_load_wav_bytes( QuickVec<unsigned char> &out_buffer, const char *_id,  int *channels, int* rate, int *bitrate, int *bits_per_sample );

	std::string ogg_error_string(int code);

		//other defines
    #define OGG_BUFFER_LENGTH 4096
        // 0 for Little-Endian, 1 for Big-Endian
    #ifdef HXCPP_BIG_ENDIAN
        #define OGG_BUFFER_READ_TYPE 1
    #else
        #define OGG_BUFFER_READ_TYPE 0
    #endif



//OGG file source construct

    class OGG_file_source : public Object {

        public:
            lumen_iosrc*        file_source;
            ov_callbacks        callbacks;
            std::string         source_name;
            OggVorbis_File*     ogg_file;
            vorbis_info*        info;
            vorbis_comment*     comments;
            off_t               offset;
            off_t               length;
            off_t               length_pcm;

        OGG_file_source() : offset(0), length(0), length_pcm(0) {

            ogg_file = new OggVorbis_File();

        } //OGG_file_source

        ~OGG_file_source() {

            ov_clear(ogg_file);
            delete ogg_file;

        } //~

    }; //OGG_file_source



} //namespace lumen

#endif //_LUMEN_ASSETS_AUDIO_