-- (c) Copyright 1995-2020 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:xbip_multadd:3.0
-- IP Revision: 13

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY xbip_multadd_v3_0_13;
USE xbip_multadd_v3_0_13.xbip_multadd_v3_0_13;

ENTITY fma_u32 IS
  PORT (
    A : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    C : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    SUBTRACT : IN STD_LOGIC;
    P : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    PCOUT : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
  );
END fma_u32;

ARCHITECTURE fma_u32_arch OF fma_u32 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF fma_u32_arch: ARCHITECTURE IS "yes";
  COMPONENT xbip_multadd_v3_0_13 IS
    GENERIC (
      C_VERBOSITY : INTEGER;
      C_XDEVICEFAMILY : STRING;
      C_A_WIDTH : INTEGER;
      C_B_WIDTH : INTEGER;
      C_C_WIDTH : INTEGER;
      C_A_TYPE : INTEGER;
      C_B_TYPE : INTEGER;
      C_C_TYPE : INTEGER;
      C_CE_OVERRIDES_SCLR : INTEGER;
      C_AB_LATENCY : INTEGER;
      C_C_LATENCY : INTEGER;
      C_OUT_HIGH : INTEGER;
      C_OUT_LOW : INTEGER;
      C_USE_PCIN : INTEGER;
      C_TEST_CORE : INTEGER
    );
    PORT (
      CLK : IN STD_LOGIC;
      CE : IN STD_LOGIC;
      SCLR : IN STD_LOGIC;
      A : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      C : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      PCIN : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
      SUBTRACT : IN STD_LOGIC;
      P : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      PCOUT : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
    );
  END COMPONENT xbip_multadd_v3_0_13;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF fma_u32_arch: ARCHITECTURE IS "xbip_multadd_v3_0_13,Vivado 2018.3";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF fma_u32_arch : ARCHITECTURE IS "fma_u32,xbip_multadd_v3_0_13,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF fma_u32_arch: ARCHITECTURE IS "fma_u32,xbip_multadd_v3_0_13,{x_ipProduct=Vivado 2018.3,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xbip_multadd,x_ipVersion=3.0,x_ipCoreRevision=13,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_VERBOSITY=0,C_XDEVICEFAMILY=zynq,C_A_WIDTH=32,C_B_WIDTH=32,C_C_WIDTH=32,C_A_TYPE=1,C_B_TYPE=1,C_C_TYPE=1,C_CE_OVERRIDES_SCLR=0,C_AB_LATENCY=0,C_C_LATENCY=0,C_OUT_HIGH=31,C_OUT_LOW=0,C_USE_PCIN=0,C_TEST_CORE=0}";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF PCOUT: SIGNAL IS "XIL_INTERFACENAME pcout_intf, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF PCOUT: SIGNAL IS "xilinx.com:signal:data:1.0 pcout_intf DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF P: SIGNAL IS "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF P: SIGNAL IS "xilinx.com:signal:data:1.0 p_intf DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF SUBTRACT: SIGNAL IS "XIL_INTERFACENAME subtract_intf, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF SUBTRACT: SIGNAL IS "xilinx.com:signal:data:1.0 subtract_intf DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF C: SIGNAL IS "XIL_INTERFACENAME c_intf, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF C: SIGNAL IS "xilinx.com:signal:data:1.0 c_intf DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF B: SIGNAL IS "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF B: SIGNAL IS "xilinx.com:signal:data:1.0 b_intf DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF A: SIGNAL IS "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF A: SIGNAL IS "xilinx.com:signal:data:1.0 a_intf DATA";
BEGIN
  U0 : xbip_multadd_v3_0_13
    GENERIC MAP (
      C_VERBOSITY => 0,
      C_XDEVICEFAMILY => "zynq",
      C_A_WIDTH => 32,
      C_B_WIDTH => 32,
      C_C_WIDTH => 32,
      C_A_TYPE => 1,
      C_B_TYPE => 1,
      C_C_TYPE => 1,
      C_CE_OVERRIDES_SCLR => 0,
      C_AB_LATENCY => 0,
      C_C_LATENCY => 0,
      C_OUT_HIGH => 31,
      C_OUT_LOW => 0,
      C_USE_PCIN => 0,
      C_TEST_CORE => 0
    )
    PORT MAP (
      CLK => '0',
      CE => '0',
      SCLR => '0',
      A => A,
      B => B,
      C => C,
      PCIN => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 48)),
      SUBTRACT => SUBTRACT,
      P => P,
      PCOUT => PCOUT
    );
END fma_u32_arch;
