// uz1d.h --- One dimensional transport.
// 
// Copyright 2006 Per Abrahamsen and KVL.
//
// This file is part of Daisy.
// 
// Daisy is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser Public License as published by
// the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
// 
// Daisy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser Public License for more details.
// 
// You should have received a copy of the GNU Lesser Public License
// along with Daisy; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#ifndef UZ1D_H
#define UZ1D_H

#include "geometry_rect.h"
#include "soil.h"
#include "soil_water.h"
#include "soil_heat.h"
#include <vector>

class SMM1D
{
  // Content.
  const GeometryRect& geo;
  const Soil& soil;
  SoilWater& soil_water;
  const SoilHeat& soil_heat;
  const std::vector<size_t> cells;
  const std::vector<int> edges;
  const std::vector<double> edge_distance_;

  // Geometry.
public:
  size_t cell_size () const
  { return cells.size (); }
  double cell_distance (const size_t index) const
  { 
    const size_t cell = cells[index];
    return geo.dz (cell);
  }
  double center (const size_t index) const
  { 
    const size_t cell = cells[index];
    return geo.z (cell);
  }
  size_t edge_previous (const size_t i) const
  { return i; }
  size_t edge_next (const size_t i) const
  { return i + 1; }
  double edge_distance (const size_t i) const
  { return edge_distance_[i]; }

  // Hydraulic.
public:
  double K (const size_t index, const double h) const
  { 
    const size_t cell = cells[index];
    return soil.K (cell, h, soil_water.h_ice (cell), soil_heat.T (cell));
  }
  double Cw1 (const size_t index, const double h) const
  {
    const size_t cell = cells[index];
    return soil.Cw1 (cell, h, soil_water.h_ice (cell));
  }
  double Cw2 (const size_t index, const double h) const
  {
    const size_t cell = cells[index];
    return soil.Cw2 (cell, h);
  }
  double Theta (const size_t index, const double h) const
  {
    const size_t cell = cells[index];
    return soil.Theta (cell, h, soil_water.h_ice (cell));
  } 
  double Theta_old (const size_t index) const
  {
    const size_t cell = cells[index];
    return soil_water.Theta_old (cell);
  } 

  // Update.
public:
  void reset (std::vector<double>& h, std::vector<double>& Theta) const;
  void update (const std::vector<double>& h,
               const std::vector<double>& Theta,
               const std::vector<double>& q);

  // Create and Destroy.
public:
  static std::vector<double>
  /**/ calculate_edge_distance (const GeometryRect& geo,
                                const std::vector<size_t>& cells);
  SMM1D (const GeometryRect&, const Soil&,
         SoilWater&, const SoilHeat&,
         const std::vector<size_t>& cells, const std::vector<int>& edges);
};

class UZ1D
{
  // Content.
public: 
  const symbol name;
  static const char *const description;

  // Simulate.
public:
  virtual void tick (SMM1D&, double gravity, Treelog&) = 0;

  // Create and Destroy.
public:
  static const AttributeList& default_model ();
private:
  UZ1D ();
  UZ1D (const UZ1D&);
  UZ1D& operator= (const UZ1D&);
protected:
  explicit UZ1D (Block&);
public:
  virtual ~UZ1D ();
};

#ifdef FORWARD_TEMPLATES
template<>
Librarian<UZ1D>::Content* Librarian<UZ1D>::content;
#endif

static Librarian<UZ1D> UZ1D_init ("uz1d");

#endif // UZ1D_H