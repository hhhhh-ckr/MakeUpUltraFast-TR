#version 120
/* MakeUp - gbuffers_block.vsh
Render: Beacon beam

Javier Garduño - GNU Lesser General Public License v3.0
*/

#ifdef USE_BASIC_SH
  #define UNKNOWN_DIM
#endif
#define GBUFFER_BLOCK

#include "/common/solid_blocks_vertex.glsl"
