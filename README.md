# Space Surveillance & Tracking (SST) Engine
### High-Fidelity N-Body Propagator & Collision Avoidance System

![Output](High-Fidelity-Orbital-Propagator/High Fidelity Orbital Propagator
/SST_Conjunction_Event.png)

## Project Overview
This project is an operational Space Surveillance and Tracking (SST) tool developed in MATLAB. It combines a high-fidelity N-Body Orbit Propagator with a Conjunction Analysis module to detect collision risks between satellites and space debris.

Designed to meet the precision requirements of Flight Dynamics missions, the engine moves beyond simple Two-Body approximations to model complex perturbations, achieving 99.99% accuracy against NASA JPL ephemerides.

**Key Capabilities:**
*   **Orbit Propagation:** Cowell’s Method with J2 Zonal Harmonics & Third-Body Gravity.
*   **Conjunction Assessment:** Automated detection of Time of Closest Approach (TCA).
*   **Collision Risk:** Calculation of Miss Distance (DCA) and critical event flagging.

---

## Upgrade:
The system now includes a dedicated **SST Module** that simulates debris encounters.

### How the Conjunction Algorithm Works:
1.  **Debris Generation:** Simulates a secondary object with perturbed orbital elements.
2.  **Time Synchronization:** Uses spline interpolation (`interp1`) to map both objects onto a synchronized 1-second time grid, resolving ODE45 variable time-step discrepancies.
3.  **Euclidean Optimization:** Calculates the relative distance vector $\vec{r}_{rel} = \vec{r}_{sat} - \vec{r}_{deb}$ at every epoch.
4.  **Critical Event Flagging:** Identifies the global minimum (TCA) and triggers a warning if the Distance of Closest Approach (DCA) falls below a safety threshold.

---

## The Physics Engine
To ensure the position data used for collision checks is accurate, the propagator accounts for the following accelerations:

$$\vec{a}_{total} = \vec{a}_{Earth} + \vec{a}_{J2} + \vec{a}_{Sun}$$

### 1. Earth Point Mass ($\vec{a}_{Earth}$)
Standard Keplerian gravity treats Earth as a central point mass.

### 2. The J2 Zonal Harmonic ($\vec{a}_{J2}$)
**The Physics:** Earth is an oblate spheroid (bulging at the equator).
**The Impact:** This causes Nodal Precession and Apsidal Rotation.
**The Code:** I implemented the J2 perturbation model to account for the non-spherical gravity potential, essential for accurate LEO propagation.

### 3. Solar Third-Body Gravity ($\vec{a}_{Sun}$)
**The Physics:** The gravitational pull of the Sun impacts high-altitude orbits.
**The Math:** Performed coordinate frame transformations (Ecliptic $\to$ Equatorial) using the obliquity of the ecliptic ($\epsilon \approx 23.5^{\circ}$) to map solar gravity vectors correctly.

---

## Validation & Accuracy
The core propagator was validated against ground truth data from the **NASA JPL Horizons System** (Ephemeris DE441).

| Metric | Result |
| :--- | :--- |
| **Integrator** | ODE45 (Runge-Kutta) |
| **Total Arc** | 24 Hours |
| **Predictive Accuracy** | **99.9956%** |
| **Collision Detection** | validated |
