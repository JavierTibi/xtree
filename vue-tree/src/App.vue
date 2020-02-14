<template>
  <div id="app">
    <tree></tree>
  </div>
</template>

<script>
import Tree from './components/Tree.vue'

export default {
  name: 'app',
  components: {
    Tree
  }
}
</script>

<style>
*, :after, :before, legend {
  box-sizing: border-box;
}
</style>
