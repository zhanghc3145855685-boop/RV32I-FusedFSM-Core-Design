# --- 1. 路径与环境定义 ---
set scaler_factor      0.8 ;
set core_clk_period    4.54 ; # 220MHz 对应 4.545ns
set TARGET_CLK_PERIOD [expr $core_clk_period * $scaler_factor]

set TOP_MODULE riscv

set TOP_DIR       [pwd]
set RTL_DIR       "${TOP_DIR}/rtl"
set INCLUDE_DIR   "${TOP_DIR}/includes"
set LIB_DIR       "${TOP_DIR}/lib"
set WORK_DIR      "${TOP_DIR}/work"
set RPT_DIR       "${TOP_DIR}/rpt"
set NETLIST_DIR   "${TOP_DIR}/netlist"

# 强制创建目录
file mkdir $WORK_DIR
file mkdir $RPT_DIR
file mkdir $NETLIST_DIR

# --- 2. 库文件设置 ---
set timing_enable_multiple_clocks_per_reg  true
set compile_keep_original_for_external_reference  true
set hdlin_check_no_latch  true

# 这里的 sram_ss.db 请替换为你 SRAM 库的真实文件名
set SRAM_DB "ts1n65lpll2048x64m8_220a_sslp08v125c.db"
set STD_DB  "tcbn65lpwc.db" ;

set search_path [concat $search_path $RTL_DIR $INCLUDE_DIR $LIB_DIR]

# 工艺角选择：target_library 仅包含标准单元库
set target_library [list $STD_DB]

# link_library 包含标准单元库、SRAM库和合成库
set synthetic_library [list standard.sldb dw_foundation.sldb]
set link_library [concat "*" $target_library $SRAM_DB $synthetic_library]

# --- 3. 读取 RTL 与 设计准备 ---
define_design_lib WORK -path $WORK_DIR

# 建议使用通配符或 files.f 简化，这里保留你的原始格式并确保顺序
analyze -format verilog [list ${RTL_DIR}/ALU.v ${RTL_DIR}/ControlUnit.v ${RTL_DIR}/DM.v \
                              ${RTL_DIR}/EXT.v ${RTL_DIR}/Flopr.v ${RTL_DIR}/IM.v \
                              ${RTL_DIR}/IR.v ${RTL_DIR}/MUX_2to1_A.v ${RTL_DIR}/MUX_3to1_B.v \
                              ${RTL_DIR}/MUX_3to1.v ${RTL_DIR}/MUX_3to1_LMD.v ${RTL_DIR}/NPC.v \
                              ${RTL_DIR}/PC.v ${RTL_DIR}/RF.v ${RTL_DIR}/riscv.v]

elaborate $TOP_MODULE
current_design $TOP_MODULE

# 关键：将 SRAM 设为 dont_touch，避免 DC 报错或尝试修改 Macro
set_dont_touch [get_cells -hierarchical *memory*]

link
check_design > ${RPT_DIR}/check_design_pre_compile.txt

# --- 4. 约束设置 ---
create_clock -name clk -period $TARGET_CLK_PERIOD [get_ports clk]
set_clock_uncertainty -setup 0.3 [get_clock clk]
set_clock_uncertainty -hold  0.1 [get_clock clk]
set_clock_transition  0.5 [get_clock clk]

# 复位信号设为 false path
set_input_delay [expr $TARGET_CLK_PERIOD * 0.4] -clock clk [remove_from_collection [all_inputs] clk]
set_output_delay [expr $TARGET_CLK_PERIOD * 0.4] -clock clk [all_outputs]
set_false_path -from [get_ports rst*]

# 防止时钟网络优化
set_drive 0 [get_ports clk]
set_ideal_network [get_ports clk]

# --- 5. 执行综合 ---
# 由于有 SRAM Macro，建议不解散层级，方便后端 P&R 放置
compile_ultra -no_autoungroup

# 命名规则处理
define_name_rules verilog_rule -allowed "a-zA-Z0-9_" -max_length 32 -last_restricted "_"
change_names -rules verilog_rule -hierarchy

# --- 6. 结果导出 ---
write -f verilog -hierarchy -output ${NETLIST_DIR}/${TOP_MODULE}.v
write -f ddc     -hierarchy -output ${NETLIST_DIR}/${TOP_MODULE}.ddc
write_sdc ${NETLIST_DIR}/${TOP_MODULE}.sdc

# --- 7. 报告生成 ---

# 1. 基础检查：检查时序设置和设计完整性
check_timing > ${RPT_DIR}/check_timing.rpt
check_design > ${RPT_DIR}/check_design_final.rpt

# 2. 面积报告
report_area -hierarchy > ${RPT_DIR}/report_area.rpt

# 3. 时序报告：分别生成 Setup (Max) 和 Hold (Min) 报告
report_timing -delay_type max -max_paths 10 > ${RPT_DIR}/report_timing_setup.rpt
report_timing -delay_type min -max_paths 10 > ${RPT_DIR}/report_timing_hold.rpt

# 4. 违例汇总报告
report_constraint -all_violators > ${RPT_DIR}/constraints.rpt

# 5. 错误与警告专项提取（针对你之前的报错定位）
# redirect 命令会将信息捕获到指定文件，方便快速排查 LINK 或 UID 错误
redirect -file ${RPT_DIR}/errors_summary.rpt { print_message_info -info error }
redirect -file ${RPT_DIR}/warnings_summary.rpt { print_message_info -info warning }

# 6. 资源占用与功耗（可选）
report_resources > ${RPT_DIR}/report_resources.rpt
report_power     > ${RPT_DIR}/report_power.rpt

echo "=========================================================="
echo "DC Synthesis for 220MHz Completed!"
echo "Target Period: $TARGET_CLK_PERIOD ns"
echo "----------------------------------------------------------"
echo "Reports saved in: ${RPT_DIR}"
echo "Check errors_summary.rpt for any fatal link issues!"
echo "=========================================================="