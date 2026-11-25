## ADDED Requirements

### Requirement: Local Wayland lab
The site SHALL offer a real, locally executed Wayland guest at both Theseus URL layouts.

#### Scenario: Visitor boots and sends input
- **WHEN** a visitor starts the lab in a supported browser and sends Space
- **THEN** Theseus runs as PID 1 and the real Wayland client paints a different frame

### Requirement: Static release integrity
The site SHALL serve integrity-checked guest chunks, corresponding source and licenses without changing the existing serial console or community workflow.

#### Scenario: Invalid guest data
- **WHEN** a chunk is absent or differs from its locked digest
- **THEN** the lab does not mount that disk as a valid release
