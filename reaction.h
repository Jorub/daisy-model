// reaction.h --- Tranformation between soil chemicals.
// 
// Copyright 2004 Per Abrahamsen and KVL.
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


#ifndef REACTION_H
#define REACTION_H

#include "model_framed.h"

class Log;
class Geometry;
class Soil;
class SoilWater;
class SoilHeat;
class Surface;
class OrganicMatter;
class Chemistry;
class Treelog;
class BlockModel;
class Units;

class Reaction : public ModelFramed
{
  // Content.
public:
  static const char *const component;
  symbol library_id () const;

  // Simulation.
public:
  virtual void tick_top (const double tillage_age /* [d] */,
                         const double total_rain, const double direct_rain,
                          const double canopy_drip,
                          const double cover, const double h_veg, 
                          const double h_pond,
                          Chemistry& chemistry, const double dt, Treelog&);
  virtual void tick_surface (const Units&, const Geometry&, 
                             const Soil&, const SoilWater&, const SoilHeat&,
                             const Surface&, Chemistry&, const double dt,
                             Treelog& msg);
  virtual void tick_soil (const Units& units, 
                          const Geometry&, const Soil&, const SoilWater&,
                          const SoilHeat&, const OrganicMatter&, Chemistry&,
                          const double dt, Treelog&);
  virtual void output (Log&) const = 0;

  // Create and Destroy.
public:
  virtual void initialize (const Units& units, const Geometry& geo,
                           const Soil&, const SoilWater&, const SoilHeat&, 
                           const Surface&, Treelog&) = 0;
  virtual bool check (const Units& units, const Geometry& geo,
                      const Soil&, const SoilWater&, const SoilHeat&,
		      const Chemistry&, Treelog&) const = 0;
protected:
  Reaction (const BlockModel& al);
public:
  ~Reaction ();
};

#endif // REACTION_H
