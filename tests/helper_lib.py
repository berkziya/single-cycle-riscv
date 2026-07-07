import cocotb.handle
from tabulate import tabulate


# source: exp2/tests/Helper_Student.py
def ToHex(obj):
    binary_str = str(obj)
    binary_str = binary_str.strip()
    if len(binary_str) >= 8 and binary_str.replace("1", "").replace("0", "") == "":
        value = int(binary_str, 2)
        hex_len = (len(binary_str) + 3) // 4
        hex_str = format(value, "0{}x".format(hex_len))
        return "0x" + hex_str
    else:
        return binary_str


# source: exp2/tests/Helper_Student.py
def Log_Everything(instance, logger, log_submodules=False):
    submodules = []
    log_data = []

    for attribute in instance:
        # Check type using Cocotb handle classes
        if isinstance(attribute, cocotb.handle.LogicObject):
            log_data.append([attribute._name, str(attribute.value)])
        elif isinstance(attribute, cocotb.handle.LogicArrayObject):
            log_data.append([attribute._name, ToHex(attribute.value)])
        elif isinstance(attribute, cocotb.handle.HierarchyObject):
            submodules.append(attribute)
        elif isinstance(attribute, cocotb.handle.HierarchyArrayObject):
            submodules.append(attribute)

    table = tabulate(log_data, headers=["Signal", "Current Val"], tablefmt="github")
    logger.info(f"\n{table}")

    if log_submodules:
        for sub in submodules:
            logger.info(f"Submodule Detected: {sub._name}")


# source: exp2/tests/Helper_Student.py
def Log_Datapath(dut, logger):
    logger.info("\n" + "*" * 15 + " DUT DATAPATH Signals " + "*" * 15)
    Log_Everything(dut.my_datapath, logger)


# source: exp2/tests/Helper_Student.py
def Log_Controller(dut, logger):
    logger.info("\n" + "*" * 15 + " DUT CONTROLLER Signals " + "*" * 15)
    Log_Everything(dut.my_controller, logger)
