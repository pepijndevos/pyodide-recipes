"""
Example Marimo notebook for using ngspice with InSpice

To run this example:
1. Start a file server: python3 -m http.server 8000 --directory dist
2. Open this notebook in Marimo
3. Run all cells
"""

import marimo

__generated_with = "0.9.0"
app = marimo.App()


@app.cell
def install_packages():
    """Install libngspice and inspice"""
    import micropip

    # Install libngspice from local server
    # Change URL to your hosted location in production
    await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')

    # Install inspice from PyPI
    await micropip.install('inspice')

    print("✓ Packages installed successfully!")
    return


@app.cell
def verify_installation():
    """Verify that ngspice is available"""
    import os
    import importlib.util

    # Check InSpice
    if importlib.util.find_spec('InSpice'):
        print("✓ InSpice installed")
    else:
        print("✗ InSpice not found")

    # Check libngspice.so
    lib_path = '/lib/python3.12/site-packages/libngspice.libs/libngspice.so'
    if os.path.exists(lib_path):
        print(f"✓ libngspice.so found at {lib_path}")
    else:
        print(f"✗ libngspice.so not found")

    return


@app.cell
def example_voltage_divider():
    """Simple voltage divider example"""
    from InSpice.Spice.Netlist import Circuit

    # Create circuit
    circuit = Circuit('Voltage Divider')
    circuit.V('input', 1, circuit.gnd, 10)  # 10V source
    circuit.R(1, 1, 2, '1k')                # R1 = 1kΩ
    circuit.R(2, 2, circuit.gnd, '1k')      # R2 = 1kΩ

    # Simulate
    simulator = circuit.simulator()
    analysis = simulator.operating_point()

    output_voltage = float(analysis['2'])
    print(f"Input: 10V")
    print(f"Output (node 2): {output_voltage:.2f}V")
    print(f"Expected: 5V (voltage divider)")

    return circuit, analysis


@app.cell
def example_rc_transient():
    """RC circuit transient analysis"""
    from InSpice.Spice.Netlist import Circuit
    import matplotlib.pyplot as plt
    import numpy as np

    # Create RC circuit
    circuit = Circuit('RC Circuit')
    circuit.V('input', 1, circuit.gnd, 10)  # Step input
    circuit.R(1, 1, 2, '1k')
    circuit.C(1, 2, circuit.gnd, '1uF')

    # Transient analysis
    simulator = circuit.simulator()
    analysis = simulator.transient(step_time='0.1ms', end_time='10ms')

    # Extract data
    time = analysis.time.as_ndarray() * 1000  # Convert to ms
    voltage = analysis['2'].as_ndarray()

    # Plot
    plt.figure(figsize=(10, 6))
    plt.plot(time, voltage, 'b-', linewidth=2, label='Output Voltage')
    plt.axhline(y=10*0.632, color='r', linestyle='--', alpha=0.5, label='63.2% (1τ)')
    plt.xlabel('Time (ms)')
    plt.ylabel('Voltage (V)')
    plt.title('RC Circuit Step Response')
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.show()

    # Calculate time constant
    tau_idx = np.argmin(np.abs(voltage - 10*0.632))
    tau_measured = time[tau_idx]
    tau_expected = 1.0  # R*C = 1kΩ * 1µF = 1ms

    print(f"Time constant (τ):")
    print(f"  Measured: {tau_measured:.2f} ms")
    print(f"  Expected: {tau_expected:.2f} ms")

    return circuit, analysis


@app.cell
def example_rc_filter_ac():
    """RC low-pass filter frequency response"""
    from InSpice.Spice.Netlist import Circuit
    import matplotlib.pyplot as plt
    import numpy as np

    # Create RC low-pass filter
    circuit = Circuit('RC Low-Pass Filter')
    circuit.V('input', 1, circuit.gnd, 'AC 1')  # 1V AC source
    circuit.R(1, 1, 2, '1k')
    circuit.C(1, 2, circuit.gnd, '100nF')

    # AC analysis
    simulator = circuit.simulator()
    analysis = simulator.ac(
        start_frequency=10,
        stop_frequency=100e3,
        number_of_points=100,
        variation='dec'
    )

    # Extract data
    frequency = analysis.frequency.as_ndarray()
    voltage = analysis['2'].as_ndarray()
    magnitude_db = 20 * np.log10(np.abs(voltage))
    phase_deg = np.angle(voltage, deg=True)

    # Plot Bode plot
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))

    # Magnitude plot
    ax1.semilogx(frequency, magnitude_db, 'b-', linewidth=2)
    ax1.axhline(y=-3, color='r', linestyle='--', alpha=0.5, label='-3dB')
    ax1.set_ylabel('Magnitude (dB)')
    ax1.set_title('RC Low-Pass Filter Frequency Response')
    ax1.grid(True, alpha=0.3, which='both')
    ax1.legend()

    # Phase plot
    ax2.semilogx(frequency, phase_deg, 'g-', linewidth=2)
    ax2.set_xlabel('Frequency (Hz)')
    ax2.set_ylabel('Phase (degrees)')
    ax2.grid(True, alpha=0.3, which='both')

    plt.tight_layout()
    plt.show()

    # Calculate cutoff frequency
    cutoff_idx = np.argmin(np.abs(magnitude_db + 3))
    f_cutoff_measured = frequency[cutoff_idx]
    f_cutoff_expected = 1 / (2 * np.pi * 1e3 * 100e-9)  # 1/(2πRC)

    print(f"Cutoff frequency (-3dB):")
    print(f"  Measured: {f_cutoff_measured:.1f} Hz")
    print(f"  Expected: {f_cutoff_expected:.1f} Hz")

    return circuit, analysis


@app.cell
def example_diode_iv():
    """Diode I-V characteristic curve"""
    from InSpice.Spice.Netlist import Circuit
    import matplotlib.pyplot as plt
    import numpy as np

    # Create diode circuit with voltage source
    circuit = Circuit('Diode I-V Curve')
    circuit.V('sweep', 1, circuit.gnd, 0)  # Voltage to sweep
    circuit.R(1, 1, 2, '10')               # Small series resistor
    circuit.Diode(1, 2, circuit.gnd, model='1N4148')

    # Define diode model (1N4148 parameters)
    circuit.model('1N4148', 'D', IS='2.52n', RS='0.568', N='1.752',
                  CJO='4p', M='0.4', TT='20n')

    # DC sweep analysis
    simulator = circuit.simulator()
    analysis = simulator.dc(Vsweep=slice(-1, 1, 0.01))

    # Extract data
    voltage = analysis['1'].as_ndarray()
    current = analysis['Vsweep'].as_ndarray() * 1000  # Convert to mA

    # Plot
    plt.figure(figsize=(10, 6))
    plt.plot(voltage, current, 'b-', linewidth=2)
    plt.axhline(y=0, color='k', linestyle='-', linewidth=0.5)
    plt.axvline(x=0, color='k', linestyle='-', linewidth=0.5)
    plt.xlabel('Diode Voltage (V)')
    plt.ylabel('Diode Current (mA)')
    plt.title('1N4148 Diode I-V Characteristic')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

    # Find forward voltage at 1mA
    idx_1ma = np.argmin(np.abs(current - 1.0))
    v_f = voltage[idx_1ma]
    print(f"Forward voltage at 1mA: {v_f:.3f}V")

    return circuit, analysis


if __name__ == "__main__":
    app.run()
