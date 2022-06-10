
if not data.raw["locomotive"]["locomotive"].equipment_grid then
  data.raw["locomotive"]["locomotive"].equipment_grid = data.raw["locomotive"]["locomotive"].equipment_grid or "floof:grid"
  data.raw["cargo-wagon"]["cargo-wagon"].equipment_grid = data.raw["cargo-wagon"]["cargo-wagon"].equipment_grid or "floof:grid"
  data.raw["fluid-wagon"]["fluid-wagon"].equipment_grid = data.raw["fluid-wagon"]["fluid-wagon"].equipment_grid or "floof:grid"
  data.raw["artillery-wagon"]["artillery-wagon"].equipment_grid = data.raw["artillery-wagon"]["artillery-wagon"].equipment_grid or "floof:grid"

  data.raw["cargo-wagon"]["cargo-wagon"].allow_robot_dispatch_in_automatic_mode = true
  data.raw.car.car.equipment_grid = data.raw.car.car.equipment_grid or "floof:grid"
  data.raw.car.tank.equipment_grid = data.raw.car.tank.equipment_grid or "floof:grid"
end
