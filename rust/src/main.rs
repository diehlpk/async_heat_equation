// 
// This file is part of the Monte carlo code exmaples (https://github.com/xxxx).
// Copyright (c) 2021 Patrick Diehl
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//

use rand::distributions::{Distribution, Uniform};
use rand::thread_rng;
use std::io;

fn main() -> io::Result<()>  {

let mut nc: f64 = 0.0;

// Generate the random number generator
let mut rng = thread_rng();
let normal =  Uniform::from(0.0..1.0);

// Ask the user for the nummber of iterations
println!("Please enter the number of iterations:");
let mut buffer = String::new();
io::stdin().read_line(&mut buffer)?;
let end : i32 = buffer.trim().parse().unwrap();

// Loop over the iterations
for _n in 1..end {

let x: f64 =  normal.sample(&mut rng);
let y: f64 =  normal.sample(&mut rng);

if x * x + y * y <= 1.0 {
    nc += 1.0;
}

}

// Compute the final result
let pi: f64 = 4. * nc / (end as f64);

// Print the final result
println!("Pi is equal to {} after {} iterations",pi,end);

Ok(())

}
