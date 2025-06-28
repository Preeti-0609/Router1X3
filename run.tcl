##########################################################################################
Router 1X3
Mini Project
##########################################################################################
#Echo command is used to display something on screen as output
echo "Welcome back Preeti :)"

#Sourcing the tcl file
#source -echo ../setup.tcl

set TECH_FILE     "../../ref/tech/saed32nm_1p9m.tf"
set REFLIB        "../../ref/CLIBs"

set REFERENCE_LIBRARY [join "
    $REFLIB/saed32_hvt.ndm
    $REFLIB/saed32_lvt.ndm
    $REFLIB/saed32_rvt.ndm
"]

#Creating a dlib file
create_lib -technology $TECH_FILE -ref_libs $REFERENCE_LIBRARY router2.dlib

#RTL code is analyzed
analyze -format verilog [glob ./rtl/*.v]

#Macros of the router_top module are listed
elaborate router_top

#Top module is set
set_top_module router_top

#saving block
save_block

#Reading Parasitic Files
read_parasitic_tech -layermap ../ref/tech/saed32nm_tf_itf_tluplus.map -tlup ../ref/tech/saed32nm_1p9m_Cmax.lv.nxtgrd -name maxTLU
read_parasitic_tech -layermap ../ref/tech/saed32nm_tf_itf_tluplus.map -tlup ../ref/tech/saed32nm_1p9m_Cmin.lv.nxtgrd -name minTLU

#upf
load_upf ./design_data/risc_core.upf
commit_upf
check_mv_design
save_block

#mcmm-execute from here
source -echo ./design_data/mcmm_router.tcl
report_modes
report_corners
report_scenarios

#reading_sdc
read_sdc ./constraints/constraints_file.sdc
report_clocks

#missing scandef
set_app_options -list {place.coarse.continue_on_missing_scandef {true}}

#layer info
get_site_defs
set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8}] routing_direction vertical
get_attribute [get_layers M1?]routing_direction


#compile flow stages
compile_fusion

#initialize floorplaN
check_netlist
initialize_floorplan -shape L -orientation W -side_ratio {2 2 1 2} -core_offset {20}

#powerplanning
connect_pg_net -automatic


#placement
create_placement -floorplan
place_pins -self
check_design -checks pre_placement_stage

check_design -checks pre_clock_tree_stage
clock_opt
check_design -checks pre_route_stage
route_auto
route_opt
route_eco

save_lib
save_block
