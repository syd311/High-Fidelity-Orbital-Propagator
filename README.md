# High-Fidelity LAGEOS-1 Orbital Propagator

This project is a high-precision N-Body orbital simulation developed in MATLAB. It propagates the trajectory of the **LAGEOS-1** satellite over a 24-hour period, accounting for complex gravitational perturbations.

The simulation was validated against NASA JPL Horizons telemetry data, achieving a predictive accuracy of 99.9956%.

The simulation integrates the Cowell Method with the following perturbations:
1.  Earth Point Mass: Standard $\mu/r^3$ gravity.
2.  J2 Zonal Harmonic: Accounts for Earth's oblateness (bulge at the equator), which causes nodal precession and apsidal rotation.
3.  Solar Gravity: Third-body perturbation from the Sun, calculated by transforming solar ephemerides from the Ecliptic to the Equatorial frame.


*   Target Satellite: LAGEOS-1 (Laser Geodynamics Satellite)
*   Duration: 24 Hours (86,400 seconds)
*   Ground Truth: NASA JPL Horizons System (Ephemeris DE441)
*   Result:
    *   Position Error: ~5 km (over ~400,000 km travel distance)
    *   Accuracy: 99.9956%

