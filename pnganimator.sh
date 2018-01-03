#!/bin/bash
#
# Generate a simple animation GIF from png image.
#

set -e

#
# Constant Values
#
readonly PNGANIMATOR_DIR=`dirname $0`
readonly PNGANIMATOR_NAME=`basename $0`

# Default option values
readonly DEFAULT_OPT_FRAME=8 #45 # 30
readonly DEFAULT_OPT_DELAY=8  # 7


#
# Support Functions
#
usage() {
    cat << __EOS__
Usage: $PNGANIMATOR_NAME [-s SPEED] [-f FRAME] [-d DEST_FILE] [-o] [-v] [-x] anim_mode input_file.png

Description:
    Generate a simple animation GIF from png image.

Animation Mode:
    rotate  - Generate animation GIF in wich the image ratates.
    move    - Generate animation GIF in wich the image moves. (TODO)

Options:
    -s  Animation Speed. Default $OPT_FRAME_DEFAULT.
    -f  Animation Frames. Default $OPT_DELAY_DEFAULT.
    -d  Destination File Name Base.
    -o  Run optimize.
    -v  Verbose Mode.
    -x  Debug Mode.
    -h  Show help.

__EOS__
}


#
# Prepare temporary directory
#
unset tmp_dir

on_exit() {
  [[ -n "${tmp_dir}" ]] && rm -rf "${tmp_dir}";
}
trap on_exit EXIT
trap 'trap - EXIT; on_exit; exit -1' INT PIPE TERM

readonly tmp_dir=`mktemp -d "/tmp/${PNGANIMATOR_NAME}.tmp.XXXXXX"`


#
# PngAnimator Main
#
main() {
  # Load lib
  . "$PNGANIMATOR_DIR/lib.sh"

  # Args & Options
  local anim_mode=''
  local output_filename_base=''
  local flag_optimize='false'
  local opt_frame=$DEFAULT_OPT_FRAME
  local opt_delay=$DEFAULT_OPT_DELAY
  local opt_resize=''

  while getopts d:of:s:r:vxh flag; do
    case "${flag}" in
      # Common options
      d ) output_filename_base="${OPTARG}" ;;
      o ) flag_optimize='true' ;;

      # Animation option
      f ) opt_frame="${OPTARG}" ;;
      s ) opt_delay="${OPTARG}" ;;
      r )
        if [[ ${OPTARG} =~ ^([0-9])+$ ]] ; then
          opt_resize="${OPTARG}" ;
        else
          err "error: resize option should specify number only. specified '${OPTARG}'" ;
          usage ; exit 1 ;
        fi
        ;;

      # Debugging
      v ) LOG_LEVEL=1 ;;
      x ) LOG_LEVEL=2 ;;

      # Helps / Error
      h ) usage ; exit 1 ;;
      * ) err "error: Unexpected option '${flag}'" ; usage ; exit 1 ;;
    esac
  done
  readonly LOG_LEVEL

  shift `expr $OPTIND - 1`
  readonly anim_mode=$1
  readonly input_file_path=$2

  if [ -z "${input_file_path}" ]; then
    err "error: no input file."
    usage
    exit 1
  fi

  # If not specified, use input file name without extension.
  if [ -z "${output_filename_base}" ]; then
    local input_filename=`basename ${input_file_path}`
    output_filename_base=${input_filename%.*}
  fi
  readonly output_filename_base

  readonly flag_optimize
  readonly opt_frame
  readonly opt_delay

  logd "---------- Args & Options ----------"
  logd "## Global Variables"
  logd "PngAnimator Dir: ${PNGANIMATOR_DIR}"
  logd "PngAnimator Name: ${PNGANIMATOR_NAME}"
  logd "Log Level: ${LOG_LEVEL}"
  logd
  logd "## Input / Output"
  logd "Input File Path: ${input_file_path}"
  logd "Output File Name Base: ${output_filename_base}"
  logd
  logd "## Common Options"
  logd "Anim Mode: ${anim_mode}"
  logd "Optimize Flag: ${flag_optimize}"
  logd
  logd "## Animation Options"
  logd "Frame: ${opt_frame}"
  logd "Speed: ${opt_delay}"
  logd "Resize: ${opt_resize}"
  logd
  logd "## Temporary Dirs"
  logd "TmpDir: ${tmp_dir}"
  logd

  #---------------------------------------------------------
  # Resize
  local src_file_path="${input_file_path}"
  if [ -n "${opt_resize}" ] ; then
    local resize_image_path="${tmp_dir}/${src_file_path}"
    cp "${src_file_path}" "${resize_image_path}"
    resize "${resize_image_path}" "${opt_resize}"
    src_file_path="${resize_image_path}"
  fi

  #---------------------------------------------------------
  # Animation
  case "${anim_mode}" in
    rotate )
      rotate "${src_file_path}" \
             "${output_filename_base}" \
             "${tmp_dir}" \
             $opt_frame $opt_delay "${flag_optimize}"
      ;;

    move )
      echo "todo"
      ;;

    * )
      err "error: Unexpected Animation Mode Specified '${mode}'"
      exit 1
      ;;
  esac

  exit 0
}

main $@
