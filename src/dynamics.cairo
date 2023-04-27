// Placeholder functions to check compilation, will be replaced.

use core::traits::PartialEq;
use core::traits::PartialOrd;
use shoshin_cairo_1::numerics::Fixed;
use shoshin_cairo_1::numerics::FixedType;
use shoshin_cairo_1::numerics;

const DELTA_SCALE: u128 = 1844674407370955161_u128; // numerics::ONE_u128 / 10_u128;
const GRAVITY_ACC: u128 = 38738162554790058393600_u128; // numerics::ONE_u128 * 2100_u128;
const X_LIMIT: u128 = 7378697629483820646400_u128; // numerics::ONE_u128 * 400_u128;

fn abs_value(x: FixedType) -> FixedType {
    if (x < Fixed::zero()) {
        -x
    } else {
        x
    }
}

// Placeholder end.

enum CharacterType {
    Antoc: (),
    Jessica: (),
}

#[derive(Copy, Drop)]
struct Vec2 {
    x: FixedType,
    y: FixedType,
}

#[derive(Copy, Drop)]
struct PhysicsState {
    pos: Vec2,
    vel_fp: Vec2,
    acc_fp: Vec2,
}

trait CharacterPhysics<T> {
    // Dynamics related constants
    fn MAX_VEL_MOVE_FP() -> FixedType;
    fn MIN_VEL_MOVE_FP() -> FixedType;

    fn MAX_VEL_DASH_FP() -> FixedType;
    fn MIN_VEL_DASH_FP() -> FixedType;

    fn MOVE_ACC_FP() -> FixedType;
    fn DASH_ACC_FP() -> FixedType;

    fn DASH_VEL_FP() -> FixedType; // TODO

    fn KNOCK_VEL_X_FP() -> FixedType;
    fn KNOCK_VEL_Y_FP() -> FixedType;

    fn DEACC_FP() -> FixedType;

    // Dimension related constants
    fn BODY_KNOCKED_ADJUST_W() -> FixedType;
    // TODO

    // Action related constants
    // TODO

    // Stamina effects related constants
    // TODO

    // Body state related constants
    // TODO

    //

    // common body state getters
    fn is_in_move_forward(ref self: T) -> bool;
    fn is_in_move_backward(ref self: T) -> bool;
    fn is_in_dash_forward(ref self: T) -> bool;
    fn is_in_dash_backward(ref self: T) -> bool;
    fn is_in_knocked(ref self: T) -> bool;

    // dir() should return either 1 or -1.
    fn dir(ref self: T) -> bool;
    fn counter(ref self: T) -> u128;
}

#[derive(PartialEq, Copy, Drop)]
enum AntocBodyState {
    Idle: (),
    Hori: (),
    Vert: (),
    Block: (),
    Hurt: (),
    Knocked: (),
    MoveForward: (),
    MoveBackward: (),
    DashForward: (),
    DashBackward: (),
}

#[derive(Copy, Drop)]
struct Antoc {
    body_state: AntocBodyState,
    dir: bool,
    counter: u128,
}

impl AntocPhysics of CharacterPhysics::<Antoc> {
    // Dynamics
    // Note: https://github.com/starkware-libs/cairo/pull/2563
    fn MAX_VEL_MOVE_FP() -> FixedType {
        Fixed::new(100_u128, false)
    }
    fn MIN_VEL_MOVE_FP() -> FixedType {
        Fixed::new(100_u128, true)
    }

    fn MAX_VEL_DASH_FP() -> FixedType {
        Fixed::new(900_u128, false)
    }
    fn MIN_VEL_DASH_FP() -> FixedType {
        Fixed::new(900_u128, true)
    }

    fn DASH_VEL_FP() -> FixedType {
        Fixed::new(0_u128, false)
    }

    fn MOVE_ACC_FP() -> FixedType {
        Fixed::new(300_u128, false)
    }
    fn DASH_ACC_FP() -> FixedType {
        Fixed::new(900_u128, false)
    }

    fn KNOCK_VEL_X_FP() -> FixedType {
        Fixed::new(150_u128, false)
    }
    fn KNOCK_VEL_Y_FP() -> FixedType {
        Fixed::new(400_u128, false)
    }

    fn DEACC_FP() -> FixedType {
        Fixed::new(10000_u128, false)
    }

    // Dimension

    fn BODY_KNOCKED_ADJUST_W() -> FixedType {
        Fixed::zero() // TODO // Self::BODY_KNOCKED_LATE_HITBOX_W - Self::BODY_HITBOX_W;
    }

    // body state
    fn is_in_move_forward(ref self: Antoc) -> bool {
        self.body_state == AntocBodyState::MoveForward(())
    }

    fn is_in_move_backward(ref self: Antoc) -> bool {
        self.body_state == AntocBodyState::MoveBackward(())
    }

    fn is_in_dash_forward(ref self: Antoc) -> bool {
        self.body_state == AntocBodyState::DashForward(())
    }

    fn is_in_dash_backward(ref self: Antoc) -> bool {
        self.body_state == AntocBodyState::DashBackward(())
    }

    fn is_in_knocked(ref self: Antoc) -> bool {
        self.body_state == AntocBodyState::Knocked(())
    }

    fn dir(ref self: Antoc) -> bool {
        self.dir
    }

    fn counter(ref self: Antoc) -> u128 {
        self.counter
    }
}

// update_pos
fn update_pos(
    pos: Vec2,
    vel_next: Vec2,
    acc_next: Vec2,
) -> PhysicsState {
    // euler_forward_pos_no_hitbox
    let delta_pos_x = vel_next.x * Fixed::new(DELTA_SCALE, false);
    let delta_pos_y = vel_next.y * Fixed::new(DELTA_SCALE, false);
    
    return PhysicsState{
        pos: Vec2{x: pos.x + delta_pos_x, y: pos.y + delta_pos_y},
        vel_fp: vel_next,
        acc_fp: acc_next,
    };
}

// update_vel updates the velocity with the given accelaration.
// Returns the updated velocity.
fn update_vel(
    vel_fp: Vec2,
    acc_fp: Vec2,
    max_vel: FixedType,
    min_vel: FixedType,
) -> Vec2 {
    return euler_forward_vel_no_hitbox(
        vel_fp, 
        acc_fp,
        max_vel,
        min_vel,
    );
}


fn euler_forward_no_hitbox<C, impl Physics: CharacterPhysics::<C>, impl CharacterDrop: Drop::<C>>(mut character: C, physics_state: PhysicsState) -> PhysicsState {
    // TODO: cap logic not yet added

    if (character.is_in_move_forward()) {
        let acc_x = Physics::MOVE_ACC_FP().mul_sign(!character.dir());
        let acc_y = Fixed::zero();
        let vel_fp_next = update_vel(physics_state.vel_fp, Vec2{ x: acc_x, y: acc_y }, Physics::MAX_VEL_MOVE_FP(), Physics::MIN_VEL_MOVE_FP());
        return update_pos(physics_state.pos, vel_fp_next, Vec2{ x: acc_x, y: acc_y });
    }
    
    if (character.is_in_move_backward()) {
        let acc_fp_x = Physics::MOVE_ACC_FP().mul_sign(character.dir());
        let acc_fp_y = Fixed::zero();
        let vel_fp_next = update_vel(physics_state.vel_fp, Vec2{ x: acc_fp_x, y: acc_fp_y }, Physics::MAX_VEL_MOVE_FP(), Physics::MIN_VEL_MOVE_FP());
        return update_pos(physics_state.pos, vel_fp_next, Vec2{ x: acc_fp_x, y: acc_fp_y });
    } 
    
    if (character.is_in_dash_forward()) {
        let vel = Physics::DASH_VEL_FP().mul_sign(!character.dir());
        let vel_fp_next = if (character.counter() == 1_u128) {
            Vec2{x: vel, y: Fixed::zero()}
        } else {
            Vec2{x: Fixed::zero(), y: Fixed::zero()}
        };
        let acc_fp_x = Fixed::zero();
        let acc_fp_y = Fixed::zero();
        return update_pos(physics_state.pos, vel_fp_next, Vec2{ x: acc_fp_x, y: acc_fp_y });
    } 
    
    if (character.is_in_dash_backward()) {
        let vel = Physics::DASH_VEL_FP().mul_sign(character.dir());
        let vel_fp_next = if (character.counter() == 1_u128) {
            Vec2{x: vel, y: Fixed::zero()}
        } else {
            Vec2{x: Fixed::zero(), y: Fixed::zero()}
        };
        let acc_fp_x = Fixed::zero();
        let acc_fp_y = Fixed::zero();
        return update_pos(physics_state.pos, vel_fp_next, Vec2{x: Fixed::zero(), y: Fixed::zero()});
    }

    if (character.is_in_knocked()) {
        let (vel, acc) = if (character.counter() == 0_u128) {
            let vel_fp_y = Physics::KNOCK_VEL_Y_FP();
            let vel_fp_x = Physics::KNOCK_VEL_X_FP().mul_sign(character.dir());
            (Vec2{x: vel_fp_x, y: vel_fp_y}, Vec2{x: Fixed::zero(), y: Fixed::zero()})
        } else {
            let vel_x = if (character.counter() == 9_u128) {
                Fixed::zero()
            } else {
                physics_state.vel_fp.x
            };
            let vel_y = physics_state.vel_fp.y;
            let acc_x = Fixed::zero();
            let acc_y = Fixed::new(GRAVITY_ACC, true);
            (Vec2{x: vel_x, y: vel_y}, Vec2{x: acc_x, y: acc_y})
        };
        let vel_next = update_vel(physics_state.vel_fp, Vec2{x: acc.x, y: acc.y}, Physics::MAX_VEL_DASH_FP(), Physics::MIN_VEL_DASH_FP());
        return update_pos(physics_state.pos, vel_next, acc);
    }

    else {
        return PhysicsState {
            pos: physics_state.pos,
            vel_fp: Vec2{x: Fixed::zero(), y: Fixed::zero()},
            acc_fp: Vec2{x: Fixed::zero(), y: Fixed::zero()},
        };
    }

    // TODO
}

fn euler_forward_vel_no_hitbox(
    vel_fp: Vec2, acc_fp: Vec2, max_vel_x_fp: FixedType, min_vel_x_fp: FixedType
) -> Vec2 {
    let delta_vel_x = acc_fp.x * Fixed::new(DELTA_SCALE, false);
    let delta_vel_y = acc_fp.y * Fixed::new(DELTA_SCALE, false);

    let vel_fp_next_x = cap_fp(vel_fp.x + delta_vel_x, max_vel_x_fp, min_vel_x_fp);
    let vel_fp_next_y = vel_fp.y + delta_vel_y;

    return Vec2{x: vel_fp_next_x, y: vel_fp_next_y};
}

fn cap_fp(x_fp: FixedType, max_fp: FixedType, min_fp: FixedType) -> FixedType {
    // TODO: comparison may need importing corelib traits
    if (max_fp < x_fp) {
        return max_fp;
    }

    if (x_fp < min_fp) {
        return min_fp;
    }

    return x_fp;
}

fn is_cap_fp(x_fp: FixedType, max_fp: FixedType, min_fp: FixedType) -> bool {
    true // TODO
}

fn euler_forward_consider_hitbox(
    physics_state_0: PhysicsState,
    physics_state_cand_0: PhysicsState,
    physics_state_1: PhysicsState,
    physics_state_cand_1: PhysicsState,
    body_dim_0: Vec2,
    body_dim_1: Vec2,
    body_overlap: bool,
    agent_0_ground: bool,
    agent_1_ground: bool,
    agent_0_knocked: bool,
    agent_1_knocked: bool,
) -> (PhysicsState, PhysicsState) {
    let mut y_0_ground_handled: FixedType = Fixed::zero();
    let mut y_1_ground_handled: FixedType = Fixed::zero();
    let mut vy_fp_0_ground_handled: FixedType = Fixed::zero();
    let mut vy_fp_1_ground_handled: FixedType = Fixed::zero();

    if (agent_0_ground) {
        y_0_ground_handled = Fixed::zero();
        vy_fp_0_ground_handled = Fixed::zero();
    } else {
        y_0_ground_handled = physics_state_cand_0.pos.y;
        vy_fp_0_ground_handled = physics_state_cand_0.vel_fp.y
    }

    if (!body_overlap) {
        let physics_state_fwd_0 = PhysicsState {
            pos: Vec2{x: physics_state_cand_0.pos.x, y: y_0_ground_handled},
            vel_fp: Vec2{x: physics_state_cand_0.vel_fp.x, y: vy_fp_0_ground_handled},
            acc_fp: physics_state_cand_0.acc_fp,
        };

        let physics_state_fwd_1 = PhysicsState {
            pos: Vec2{x: physics_state_cand_1.pos.x, y: y_1_ground_handled},
            vel_fp: Vec2{x: physics_state_cand_1.vel_fp.x, y: vy_fp_1_ground_handled},
            acc_fp: physics_state_cand_1.acc_fp,
        };
    }

    //
    // Handle X component only in case body-body overlaps
    // Back the character bodies off from candidate positions using reversed candidate velocities;
    //

    let mut move_0: FixedType = Fixed::zero();
    let mut move_1: FixedType = Fixed::zero();
    let mut abs_relative_vx_fp: FixedType = Fixed::zero();

    if (is_cap_fp(physics_state_cand_0.pos.x, Fixed::new(X_LIMIT, false), Fixed::new(X_LIMIT, true))) {
        move_0 = Fixed::zero();
        move_1 = Fixed::one();
        abs_relative_vx_fp = abs_value(physics_state_cand_1.vel_fp.x);
    } else if (is_cap_fp(physics_state_cand_1.pos.x, Fixed::new(X_LIMIT, false), Fixed::new(X_LIMIT, true))) {
        move_0 = Fixed::one();
        move_1 = Fixed::zero();
        abs_relative_vx_fp = abs_value(physics_state_cand_0.vel_fp.x);
    } else {
        move_0 = Fixed::one();
        move_1 = Fixed::one();
        abs_relative_vx_fp = abs_value(physics_state_cand_1.vel_fp.x)
    }

    // note: body_dim_i contains the current body dimension
    // fix direction of backoff based on how agents are placed
    // TODO: comparison needs traits
    let (abs_distance, direction) = if (physics_state_1.pos.x > physics_state_0.pos.x) {
        (body_dim_0.x - (physics_state_cand_1.pos.x - physics_state_cand_0.pos.x), true)
    } else {
        (body_dim_1.x - (physics_state_cand_0.pos.x - physics_state_cand_1.pos.x), false)
    };

    // abs(physics_state_cand_0.vel_fp.x) = sign_vx_cand_0 * physics_state_cand_0.vel_fp.x;
    // direction = -1 if 1 to the right of 0 else 1
    let sign_vx_cand_0 = physics_state_cand_0.vel_fp.x.sign;
    let sign_vx_cand_1 = physics_state_cand_1.vel_fp.x.sign;
    let vx_fp_cand_reversed_0: FixedType = physics_state_cand_0.vel_fp.x.mul_sign(direction^sign_vx_cand_0);
    let vx_fp_cand_reversed_1: FixedType = physics_state_cand_1.vel_fp.x.mul_sign(!(direction^sign_vx_cand_1));
    // let abs_distance_fp_fp = abs_distance * SCALE_FP * SCALE_FP;

    let mut back_off_x_0_scaled: FixedType = Fixed::zero();
    let mut back_off_x_1_scaled: FixedType = Fixed::zero();

    // avoid division by 0 if abs_relative_vx_fp == Fixed::zero() 
    // use direction in order to set the sign for back_off_x_i_scaled
    if (abs_relative_vx_fp == Fixed::zero()) {
        let abs_distance_fp_half = abs_distance / Fixed::new(2_u128, false);
        // let abs_distance_fp_half = abs_distance_fp_fp / 2;
        back_off_x_0_scaled = abs_distance_fp_half * (move_0.mul_u128(2_u128) - move_1).mul_sign(direction);
        back_off_x_1_scaled = abs_distance_fp_half * (move_1.mul_u128(2_u128) - move_0).mul_sign(!direction);
    } else {
        let time_required_to_separate_fp = abs_distance / abs_relative_vx_fp;
        // let time_required_to_separate_fp = unsigned_div_rem(abs_distance_fp_fp, abs_relative_vx_fp);
        back_off_x_0_scaled = vx_fp_cand_reversed_0 * time_required_to_separate_fp;
        back_off_x_1_scaled = vx_fp_cand_reversed_1 * time_required_to_separate_fp;
    }

    let back_off_x_0 = back_off_x_0_scaled;
    let back_off_x_1 = back_off_x_1_scaled;

    //let back_off_x_0 = signed_div_rem(
    //    back_off_x_0_scaled,
    //    SCALE_FP * SCALE_FP,
    //    RANGE_CHECK_BOUND,
    //);

    //let back_off_x_1 = signed_div_rem(
    //    back_off_x_1_scaled,
    //    SCALE_FP * SCALE_FP,
    //    RANGE_CHECK_BOUND,
    //);

    let mut vx_fp_0_final: FixedType = Fixed::zero();
    let mut vx_fp_1_final: FixedType = Fixed::one();
    if (agent_0_knocked) {
        vx_fp_0_final = physics_state_cand_0.vel_fp.x;
    } else {
        vx_fp_0_final = Fixed::zero();
    }
    if (agent_1_knocked) {
        vx_fp_1_final = physics_state_cand_1.vel_fp.x;
    } else {
        vx_fp_1_final = Fixed::zero();
    }

    let physics_state_fwd_0: PhysicsState = PhysicsState {
        pos: Vec2{x: physics_state_cand_0.pos.x, y: y_0_ground_handled},
        vel_fp: Vec2{x: vx_fp_0_final, y: vy_fp_0_ground_handled},
        acc_fp: physics_state_cand_0.acc_fp,
    };
    let physics_state_fwd_1: PhysicsState = PhysicsState {
        pos: Vec2{x: physics_state_cand_1.pos.x, y: y_1_ground_handled},
        vel_fp: Vec2{x: vx_fp_1_final, y:  vy_fp_1_ground_handled},
        acc_fp: physics_state_cand_1.acc_fp,
    };

    return (physics_state_fwd_0, physics_state_fwd_1);
}