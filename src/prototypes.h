/* Advection_diffusion.c */
void advection_diffusion_parameters(struct All_variables *);
void advection_diffusion_allocate_memory(struct All_variables *);
void PG_timestep_particle(struct All_variables *);
void PG_timestep(struct All_variables *);
void predictor(struct All_variables *, float *, float *);
void corrector(struct All_variables *, float *, float *, float *);
void pg_solver(struct All_variables *, float *, float *, float *, float **, struct SOURCES, float, int, float **, unsigned int *);
void pg_shape_fn(struct All_variables *, int, struct Shape_function *, float **, double [4][9], float);
void element_residual(struct All_variables *, int, struct Shape_function, float **, float *, float *, struct SOURCES, double [9], double [4][9], float, float **, unsigned int *);
void std_timestep(struct All_variables *);
void process_heating(struct All_variables *);
/* Anisotropic_viscosity.c */
/* Boundary_conditions.c */
void velocity_boundary_conditions(struct All_variables *);
void temperature_boundary_conditions(struct All_variables *);
void velocity_refl_vert_bc(struct All_variables *);
void temperature_refl_vert_bc(struct All_variables *);
void temperature_imposed_botm_bcs(struct All_variables *, float *[], int);
void horizontal_bc(struct All_variables *, float *[], int, int, float, unsigned int, char, int);
void velocity_apply_periodic_bcs(struct All_variables *);
void temperature_apply_periodic_bcs(struct All_variables *);
void strip_bcs_from_residual(struct All_variables *, double *, int);
void temperatures_conform_bcs(struct All_variables *);
void velocities_conform_bcs(struct All_variables *, double *);
void equalize_id_ien_lm(struct All_variables *);
/* Citcom.c */
int main(int, char **);
/* Composition_adv.c */
void Runge_Kutta(struct All_variables *, float *, float *[4], int);
void Euler(struct All_variables *, float *, float *[4], int);
void transfer_markers_processors(struct All_variables *, int);
void unify_markers_array(struct All_variables *, int, int);
void prepare_transfer_arrays(struct All_variables *);
int locate_processor(struct All_variables *, double, double, double);
void get_C_from_markers(struct All_variables *, float *);
void element_markers(struct All_variables *, int);
void velocity_markers(struct All_variables *, float *[4], int);
int get_element(struct All_variables *, double, double, double, double [4]);
int in_the_domain(struct All_variables *, double, double, double);
float area_of_4node1(float, float, float, float, float, float, float, float);
float area_of_3node(float, float, float, float, float, float);
float mean_of_3node(int, float, float, float, float, float, float);
float mean_of_4node(int, float, float, float, float, float, float, float, float);
float mean_of_5node(int, float, float, float, float, float, float, float, float, float, float);
float dist1(float [4], float [4]);
/* Construct_arrays.c */
void construct_ien(struct All_variables *);
void construct_id(struct All_variables *);
void construct_lm(struct All_variables *);
void construct_node_maps(struct All_variables *);
void construct_node_ks(struct All_variables *);
void construct_masks(struct All_variables *);
void construct_sub_element(struct All_variables *);
void construct_elt_ks(struct All_variables *);
void construct_elt_gs(struct All_variables *);
void construct_mat_group(struct All_variables *);
void construct_stiffness_B_matrix(struct All_variables *);
void rebuild_BI_on_boundary(struct All_variables *);
/* Convection.c */
void set_convection_defaults(struct All_variables *);
void read_convection_settings(struct All_variables *);
void convection_derived_values(struct All_variables *);
void convection_allocate_memory(struct All_variables *);
void convection_initial_fields(struct All_variables *);
void convection_boundary_conditions(struct All_variables *);
void convection_initial_temperature(struct All_variables *);
void process_restart_tc(struct All_variables *);
void convection_initial_markers1(struct All_variables *);
void convection_initial_markers(struct All_variables *, int);
void setup_plume_problem(struct All_variables *);
void PG_process(struct All_variables *, int);
/* Drive_solvers.c */
void general_stokes_solver(struct All_variables *);
int need_to_iterate(struct All_variables *);
/* Element_calculations.c */
void assemble_forces(struct All_variables *, int);
void get_elt_k(struct All_variables *, int, double [24 * 24], int, int);
void assemble_del2_u(struct All_variables *, double *, double *, int, int);
void e_assemble_del2_u(struct All_variables *, double *, double *, int, int);
void n_assemble_del2_u(struct All_variables *, double *, double *, int, int);
void build_diagonal_of_K(struct All_variables *, int, double [24 * 24], int);
void build_diagonal_of_Ahat(struct All_variables *);
void assemble_div_u(struct All_variables *, double *, double *, int);
void assemble_grad_p(struct All_variables *, double *, double *, int);
double assemble_dAhatp_entry(struct All_variables *, int, int);
void get_elt_g(struct All_variables *, int, higher_precision [24][1], int);
void get_elt_h(struct All_variables *, int, double [1], int);
void get_elt_f(struct All_variables *, int, double [24], int, int);
void get_aug_k(struct All_variables *, int, double [24 * 24], int);
/* General_matrix_functions.c */
double **dmatrix(int, int, int, int);
float **fmatrix(int, int, int, int);
void dfree_matrix(double **, int, int, int, int);
void ffree_matrix(float **, int, int, int, int);
double *dvector(int, int);
float *fvector(int, int);
void dfree_vector(double *, int, int);
void ffree_vector(float *, int, int);
int *sivector(int, int);
void sifree_vector(int *, int, int);
double pdot(struct All_variables *, double *, double *, int);
double pselfdot(struct All_variables *, double *);
double vdot(struct All_variables *, double *, double *, int);
double vselfdot(struct All_variables *, double *, int);
double vfselfdot(struct All_variables *, float *, int);
float fdot(float *, float *, int, int);
float fselfdot(float *, int, int);
float dot(struct All_variables *, float *, float *);
float selfdot(struct All_variables *, float *);
void dvcopy(double *, double *, int, int);
void vcopy(float *, float *, int, int);
void vprod(double *, double *, double *, int, int);
float fnmax(struct All_variables *, float *, int, int);
int solve_del2_u(struct All_variables *, double *, double *, double, int, int);
double multi_grid(struct All_variables *, double *, double *, double *, double, int);
double conj_grad(struct All_variables *, double *, double *, double *, double, int *, int);
void jacobi(struct All_variables *, double *, double *, double *, double, int *, int, int);
void element_gauss_seidel(struct All_variables *, double *, double *, double *, double, int *, int, int);
void gauss_seidel1(struct All_variables *, double *, double *, double *, double, int *, int, int);
void gauss_seidel(struct All_variables *, double *, double *, double *, double, int *, int, int);
void print_elt_k(struct All_variables *, double [24 * 24]);
double cofactor(double [4][4], int, int, int);
double determinant(double [4][4], int);
float area_of_4node(float, float, float, float, float, float, float, float);
double modified_plgndr_a(int, int, double);
double sqrt_multis(int, int);
double multis(int);
int int_multis(int);
double plgndr_a(int, int, double);
double sphere_h(int, int, double, double, int);
/* Geometry_cartesian.c */
void set_2pt5dc_defaults(struct All_variables *);
void set_3ds_defaults(struct All_variables *);
void set_3dc_defaults(struct All_variables *);
/* Ggrd_handling.c */
/* Global_operations.c */
void return_horiz_sum(struct All_variables *, float *, float *, int);
void return_horiz_ave(struct All_variables *, float *, float *);
float return_bulk_value(struct All_variables *, float *, float, int);
double global_vdot(struct All_variables *, double *, double *, int);
double global_pdot(struct All_variables *, double *, double *, int);
float global_tdot(struct All_variables *, float *, float *, int);
float Tmax(struct All_variables *, float *);
float global_fmin(struct All_variables *, float);
float global_fmax(struct All_variables *, float);
void sum_across_depth_sph1(struct All_variables *, float *, float *);
void sum_across_surface(struct All_variables *, float *, int);
void sum_across_surf_sph1(struct All_variables *, float *, float *);
void gather_TG_to_me0(struct All_variables *, float *);
void propogator_down_process(struct All_variables *, float *);
double sum_across_depth(struct All_variables *, double);
/* Instructions.c */
void read_instructions(struct All_variables *, int, char **);
void allocate_common_vars(struct All_variables *);
void interruption(int);
void global_default_values(struct All_variables *);
void global_derived_values(struct All_variables *);
void read_initial_settings(struct All_variables *);
void check_bc_consistency(struct All_variables *);
void set_up_nonmg_aliases(struct All_variables *);
void report(struct All_variables *, char *);
void record(struct All_variables *, char *);
void common_initial_fields(struct All_variables *);
void initial_pressure(struct All_variables *);
void initial_velocity(struct All_variables *);
/* Nodal_mesh.c */
void node_locations(struct All_variables *);
void pre_interpolation(struct All_variables *);
void dlogical_mesh_to_real(struct All_variables *, double *, int);
void flogical_mesh_to_real(struct All_variables *, float *, int);
void p_to_nodes(struct All_variables *, double *, float *, int);
void p_to_centres(struct All_variables *, float *, double *, int);
void v_to_intpts(struct All_variables *, float *, float *, int);
void v_to_nodes(struct All_variables *, float *, float *, int);
void visc_to_intpts(struct All_variables *, float *, float *, int);
void visc_to_nodes(struct All_variables *, float *, float *, int);
void visc_from_ele_to_gint(struct All_variables *, float *, float *, int);
void visc_from_gint_to_ele(struct All_variables *, float *, float *, int);
void visc_from_gint_to_nodes(struct All_variables *, float *, float *, int);
void visc_from_nodes_to_gint(struct All_variables *, float *, float *, int);
/* Output.c */
void output_velo_related_binary(struct All_variables *, int);
void output_temp(struct All_variables *, int);
void process_restart(struct All_variables *);
void print_field_spectral_regular(struct All_variables *, float *, float *, float *, int, char *);
/* Output_gzdir.c */
void output_velo_related_gzdir(struct All_variables *, int);
void process_restart_tc_gzdir(struct All_variables *);
/* Pan_problem_misc_functions.c */
int get_process_identifier(void);
void unique_copy_file(struct All_variables *, char *, char *);
void thermal_buoyancy(struct All_variables *);
double SIN_D(double);
double COT_D(double);
void *Malloc1(int, char *, int);
int read_previous_field(struct All_variables *, float *, char *, char *);
void fcopy_interpolating(struct All_variables *, float *, float *, float *, int, int, int, float *, float *);
float cross2d(float, float, float, float, int);
void field_arbitrary_rectangle_file(struct All_variables *, int, struct Rect *, char *, float *, int, unsigned int *, unsigned int, unsigned int);
void field_arbitrary_rectangle(struct All_variables *, struct Rect *, float *, int, unsigned int *, unsigned int, unsigned int);
void field_arbitrary_circle_file(struct All_variables *, int, struct Circ *, char *, float *, int, unsigned int *, unsigned int, unsigned int);
void field_arbitrary_circle(struct All_variables *, struct Circ *, float *, int, unsigned int *, unsigned int, unsigned int);
void field_arbitrary_harmonic_file(struct All_variables *, int, struct Harm *, char *, float *, int, unsigned int *, unsigned int, unsigned int);
void field_arbitrary_harmonic(struct All_variables *, struct Harm *, float *, int, unsigned int *, unsigned int, unsigned int);
double myatan(double, double);
FILE *safe_fopen(char *, char *);
void *safe_malloc(size_t);
void calc_cbase_at_tp(float, float, float *);
void convert_pvec_to_cvec(float, float, float, float *, float *);
void rtp2xyz(float, float, float, float *);
void myerror(char *, struct All_variables *);
/* Parallel_related.c */
void parallel_process_termination(void);
void parallel_domain_decomp1(struct All_variables *);
void parallel_shuffle_ele_and_id(struct All_variables *);
void parallel_shuffle_ele_and_id_bc1(struct All_variables *);
void parallel_shuffle_ele_and_id_bc2(struct All_variables *);
void parallel_communication_routs(struct All_variables *);
void parallel_communication_routs1(struct All_variables *);
void parallel_communication_routs2(struct All_variables *);
void parallel_communication_routs3(struct All_variables *);
void parallel_communication_routs4(struct All_variables *);
void exchange_number_rec_markers(struct All_variables *);
void exchange_markers(struct All_variables *);
void exchange_id_d20(struct All_variables *, double *, int);
void exchange_node_f20(struct All_variables *, float *, int);
double CPU_time0(void);
void parallel_process_sync(void);
/* Parsing.c */
void setup_parser(struct All_variables *, char *);
void shutdown_parser(struct All_variables *);
void add_to_parameter_list(char *, char *);
int compute_parameter_hash_table(char *);
int input_int(char *, int *, char *, int);
int input_string(char *, char *, char *, int);
int input_boolean(char *, int *, char *, int);
int input_float(char *, float *, char *, int);
int input_double(char *, double *, char *, int);
int input_int_vector(char *, int, int *, int);
int input_char_vector(char *, int, char *, int);
int input_float_vector(char *, int, float *, int);
int input_double_vector(char *, int, double *, int);
int interpret_control_string(char *, int *, double *, double *, double *);
/* Phase_change.c */
/* Process_buoyancy.c */
void heat_flux(struct All_variables *);
void heat_flux1(struct All_variables *);
void plume_buoyancy_flux(struct All_variables *);
/* Process_velocity.c */
void get_surface_velo(struct All_variables *, float *);
void get_ele_visc(struct All_variables *, float *);
void get_surf_stress(struct All_variables *, float *, float *, float *, float *, float *, float *);
void averages(struct All_variables *);
/* Profiling.c */
float CPU_time(void);
/* Shape_functions.c */
double lpoly(int, double);
double lpolydash(int, double);
/* Size_does_matter.c */
void get_global_shape_fn(struct All_variables *, int, int, double [4][9], int, int);
void form_rtf_bc(int, double [4], double [4][9], double [4][4]);
void get_rtf(struct All_variables *, int, int, double [4][9], int);
void construct_c3x3matrix_el(struct All_variables *, int, struct CC *, struct CCX *, int, int);
void get_global_1d_shape_fn(struct All_variables *, int, struct Shape_function1 *, struct Shape_function1_dA *, int);
void get_global_1d_shape_fn1(struct All_variables *, int, struct Shape_function1 *, struct Shape_function1_dA *, int);
void mass_matrix(struct All_variables *);
/* Solver_conj_grad.c */
void cg_allocate_vars(struct All_variables *);
void assemble_forces_iterative(struct All_variables *);
/* Solver_multigrid.c */
void set_mg_defaults(struct All_variables *);
void mg_allocate_vars(struct All_variables *);
void project_vector(struct All_variables *, int, double *, double *, int);
void interp_vector(struct All_variables *, int, double *, double *);
void project_scalar_e(struct All_variables *, int, float *, float *);
void project_scalar(struct All_variables *, int, float *, float *);
void project_viscosity(struct All_variables *);
void inject_node_fvector(struct All_variables *, int, float **, float **);
void inject(struct All_variables *, int, double *, double *);
void un_inject_vector(struct All_variables *, int, double *, double *);
void inject_scalar(struct All_variables *, int, float *, float *);
void inject_scalar_e(struct All_variables *, int, float *, float *);
/* Sphere_harmonics.c */
void sphere_harmonics_layer(struct All_variables *, float **, float *, float *, int, char *);
void sphere_interpolate(struct All_variables *, float **, float *);
void sphere_expansion(struct All_variables *, float *, float *, float *);
void inv_sphere_harmonics(struct All_variables *, float *, float *, float *, int);
void compute_sphereh_table(struct All_variables *);
/* Stokes_flow_Incomp.c */
void solve_constrained_flow_iterative(struct All_variables *);
float solve_Ahat_p_fhat(struct All_variables *, double *, double *, double *, double, int *);
void v_from_vector(struct All_variables *, float **, double *);
/* Topo_gravity.c */
void get_CBF_topo(struct All_variables *, float *, float *);
void get_STD_topo(struct All_variables *, float *, float *, int);
/* Viscosity_structures.c */
void viscosity_parameters(struct All_variables *);
void get_viscosity_option(struct All_variables *);
void viscosity_for_system(struct All_variables *);
void get_system_viscosity(struct All_variables *, int, float *, float *);
void apply_viscosity_smoother(struct All_variables *, float *, float *);
void visc_from_mat(struct All_variables *, float *, float *);
void visc_from_T(struct All_variables *, float *, float *, int);
void visc_from_S(struct All_variables *, float *, float *, int);
void strain_rate_2_inv(struct All_variables *, float *, int);
int layers(struct All_variables *, float);
int weak_zones(struct All_variables *, int, float);
float boundary_thickness(struct All_variables *, float *);
void twiddle_thumbs(struct All_variables *, int );

void xyz2rtp(float ,float ,float ,float *);
void generate_log_message(int ,double ,double ,double , double , struct All_variables *);

void get_ba(struct Shape_function *,struct Shape_function_dx *,
	    struct CC *, struct CCX *, double [4][9],
	    int ,int, double [9][4][9][7]);

