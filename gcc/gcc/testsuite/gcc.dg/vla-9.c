/* { dg-do compile  } */
/* { dg-options "-std=c99 -W -Wall" } */
/* { dg-additional-options "-pedantic-errors" { target { size_t_ansi_compatible } } } */
/* PR c/28280 */

void f(__SIZE_TYPE__ d)
{
  typedef int t[d];
  t *g = (__typeof (g)) d;
  (void) g;
}
