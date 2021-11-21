use rand::distributions::{Distribution, Uniform};
use rand::thread_rng;
use std::io;

fn main() -> io::Result<()>  {

let mut nc: f64 = 0.0;

let mut rng = thread_rng();
let normal =  Uniform::from(0.0..1.0);


println!("Please enter the number of iterations:");
let mut buffer = String::new();
io::stdin().read_line(&mut buffer)?;

let end : i32 = buffer.trim().parse().unwrap();

for _n in 1..end {

let x: f64 =  normal.sample(&mut rng);
let y: f64 =  normal.sample(&mut rng);

if x * x + y * y <= 1.0 {
    nc += 1.0;
}

}

let pi: f64 = 4. * nc / (end as f64);


println!("Pi is equal to {} after {} iterations",pi,end);

Ok(())

}
