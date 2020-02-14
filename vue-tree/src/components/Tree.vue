<template>
  <div>
    Tree Root:
    <select v-model="selected" @change="changeTree(selected)">
      <option disabled value="-1">Please select one</option>
      <option v-for="option in options" :value="option.ID" :key="`${option.ID}-${option.parent}}`">
        {{ option.Name }}
      </option>
    </select>
    <table id="tree">
      <colgroup>
        <col width="50px">
        <col width="350px">
        <col width="50px">
        <col width="50px">
        <col width="50px">
      </colgroup>
      <thead>
        <tr> 
          <th>ID</th>
          <th>Name</th>
          <th>Order</th>
          <th>Parents</th>
          <th>Children</th>
        </tr>
      </thead>
      <tbody>
        <!-- Define a row template for all invariant markup: -->
        <tr>
          <td class="alignCenter"></td>
          <td></td>
          <td class="alignCenter"><input class="orderInput" type="input"></td>
          <td class="alignCenter"></td>
          <td class="alignCenter"></td>
        </tr>
      </tbody>
    </table>
  </div>

</template>

<script>
import $ from "jquery";

import "jquery-ui/themes/base/core.css";
import "jquery-ui/themes/base/menu.css";
import "jquery-ui/themes/base/theme.css";

import "ui-contextmenu/jquery.ui-contextmenu";

import { createTree } from "jquery.fancytree";
import "jquery.fancytree/dist/skin-lion/ui.fancytree.css";

import "jquery.fancytree/dist/modules/jquery.fancytree.edit";
import "jquery.fancytree/dist/modules/jquery.fancytree.filter";
import "jquery.fancytree/dist/modules/jquery.fancytree.table";
import "jquery.fancytree/dist/modules/jquery.fancytree.gridnav";
import "jquery.fancytree/dist/modules/jquery.fancytree.dnd5";

//keep it out of vuejs 
//to avoid perf issues
//with all the observables
let tree;

let rootSelected;

const ENDPOINT = 'http://10.30.1.127:8080/';

export default {
  name: "Tree",
  data: function () {
    return {
      selected: '-1',
      options: []
    }
  },
  methods: {
    changeTree: function(selected) {
      rootSelected = selected;
      fetch(new Request(`${ENDPOINT}getChild/${rootSelected}`))
      .then((res) => res.json())
      .then(function (nodes) {
        tree.reload(nodes)
      });
    }
  },
  mounted: function() {
    // get select options
    fetch(new Request(`${ENDPOINT}getTree`))
    .then((res) => res.json())
    .then(function (options) {
      this.$data.options = options;
    }.bind(this));

    // tree initialization
    const CLIPBOARD = {value: null};

    tree = createTree(this.$el.querySelector("#tree"), {
      debugLevel: 0,
      checkbox: false,
      extensions: ["edit", "filter", "table", "gridnav", "dnd5"],
      table: {
        indentation: 20,
        nodeColumnIdx: 1,
      },
      dnd5: {
        preventVoidMoves: true,
        preventRecursiveMoves: true,
        autoExpandMS: 400,
        dragStart: function(node, data) {
          return true;
        },
        dragEnter: function(node, data) {
          // return ["before", "after"];
          return true;
        },
        dragDrop: function(node, data) {
          data.otherNode.moveTo(node, data.hitMode);
        }
      },
      edit: {
        triggerStart: ["f2", "shift+click", "mac+enter"],
        close: function(event, data) {
          if( data.save && data.isNew ){
            // Quick-enter: add new nodes until we hit [enter] on an empty title
            this.tree.$container.trigger("nodeCommand", {cmd: "addSibling"});
          }
        }
      },
      source: fetch(new Request(`${ENDPOINT}getTreeChildren`))
      .then((res) => res.json()),
      createNode: function(event, data) {
        var node = data.node;

        // don't want to call setTitle
        // because it triggers a rename event
        node.title = node.data.Name || '';
        node.renderTitle();
      },
      renderColumns: function(event, data) {
        var node = data.node,
          $tdList = $(node.tr).find(">td");

        $tdList.eq(0).text(node.data.ID);
        $tdList.eq(2).find("input").val(node.data.Order).on('change keyup', function() {
          const myHeaders = new Headers();
          myHeaders.append('Content-Type', 'application/json');

          const myInit = { 
            method: 'PUT',
            headers: myHeaders,
            body: JSON.stringify({
              order:this.value,
            })
          };
          //                                       level >= 1          level 0
          const parent = node.parent.data.ID ? node.parent.data.ID : rootSelected
          fetch(new Request(`${ENDPOINT}edit/${node.data.ID}/parent/${parent}/order`, myInit));
        });
        $tdList.eq(3).text(node.data.ParentsCount);
        $tdList.eq(4).text(node.data.ChildrenCount);
      },
      // Events
      modifyChild: function(event, data) {
        const node = data.childNode;
        if (data.operation === 'rename') {
          if (!node.data.ID) {
            // new node added  
            const myHeaders = new Headers();
            myHeaders.append('Content-Type', 'application/json');

            const myInit = { 
              method: 'POST',
              headers: myHeaders,
              body: JSON.stringify({
                name:node.title,
                order: 0,
                //                                level >= 1          level 0
                parent: node.parent.data.ID ? node.parent.data.ID : rootSelected
              })
            };
            fetch(new Request(`${ENDPOINT}new`, myInit))
            .then(res => res.json())
            .then(function (body) {
              this.data = body;
              this.title = body.Name;
              this.tree.nodeRender({tree: this.tree, node: this, options: this.tree.options}, true);
              this.renderTitle();
            }.bind(node));
          } else {
            // node renamed
            const myHeaders = new Headers();
            myHeaders.append('Content-Type', 'application/json');

            const myInit = { 
              method: 'PUT',
              headers: myHeaders,
              body: JSON.stringify({name:node.title})
            };
            fetch(new Request(`${ENDPOINT}edit/${node.data.ID}/name`, myInit));
            //console.log(`ID node ${node.data.ID} changed name to ${node.title}`);
          }
        } else if (data.operation === 'remove') {
          if (node.data.ID) {
            // node removed
            const parent = node.parent.data.ID ? node.parent.data.ID : rootSelected;
            fetch(new Request(`${ENDPOINT}delete/${node.data.ID}/parent/${parent}`, {method: 'DELETE'}))
            // console.log(`ID node ${node.data.ID} was removed`);
          }
        } else if (data.operation === 'add') {
          // if (!node.parent.data.ID) {
          //   // moved to level 0
          //   console.log(`ID node ${node.data.ID} was moved to level 0`);
          // } else {
          //   // moved to level >= 1
          //   console.log(`ID node ${node.data.ID} was moved to parent ${node.parent.data.ID}`);
          // }
        }
      }
    });
    
    tree.$container.on("nodeCommand", function(event, data){
      // Custom event handler that is triggered by keydown-handler and
      // context menu:
      var refNode, moveMode,
        tree = $(this).fancytree("getTree"),
        node = tree.getActiveNode();

      switch( data.cmd ) {
      case "moveUp":
        refNode = node.getPrevSibling();
        if( refNode ) {
          node.moveTo(refNode, "before");
          node.setActive();
        }
        break;
      case "moveDown":
        refNode = node.getNextSibling();
        if( refNode ) {
          node.moveTo(refNode, "after");
          node.setActive();
        }
        break;
      case "indent":
        refNode = node.getPrevSibling();
        if( refNode ) {
          node.moveTo(refNode, "child");
          refNode.setExpanded();
          node.setActive();
        }
        break;
      case "outdent":
        if( !node.isTopLevel() ) {
          node.moveTo(node.getParent(), "after");
          node.setActive();
        }
        break;
      case "rename":
        node.editStart();
        break;
      case "remove":
        refNode = node.getNextSibling() || node.getPrevSibling() || node.getParent();
        node.remove();
        if( refNode ) {
          refNode.setActive();
        }
        break;
      case "addChild":
        node.editCreateNode("child", "");
        break;
      case "addSibling":
        node.editCreateNode("after", "");
        break;
      case "cut":
        CLIPBOARD.value = {mode: data.cmd, data: node};
        break;
      case "copy":
        CLIPBOARD.value = {
          mode: data.cmd,
          data: node.toDict(function(n){
            delete n.key;
          })
        };
        break;
      case "clear":
        CLIPBOARD.value = null;
        break;
      case "paste":
        if( CLIPBOARD.value.mode === "cut" ) {
          // refNode = node.getPrevSibling();
          CLIPBOARD.value.data.moveTo(node, "child");
          CLIPBOARD.value.data.setActive();
        } else if( CLIPBOARD.value.mode === "copy" ) {
          node.addChildren(CLIPBOARD.value.data).setActive();
        }
        break;
      default:
        alert("Unhandled command: " + data.cmd);
        return;
      }
    }).on("keydown", function(e){
      var cmd = null;

      // console.log(e.type, $.ui.fancytree.eventToString(e));
      switch( $.ui.fancytree.eventToString(e) ) {
      case "ctrl+shift+n":
      case "meta+shift+n": // mac: cmd+shift+n
        cmd = "addChild";
        break;
      case "ctrl+c":
      case "meta+c": // mac
        cmd = "copy";
        break;
      case "ctrl+v":
      case "meta+v": // mac
        cmd = "paste";
        break;
      case "ctrl+x":
      case "meta+x": // mac
        cmd = "cut";
        break;
      case "ctrl+n":
      case "meta+n": // mac
        cmd = "addSibling";
        break;
      case "del":
      case "meta+backspace": // mac
        cmd = "remove";
        break;
      // case "f2":  // already triggered by ext-edit pluging
      //   cmd = "rename";
      //   break;
      case "ctrl+up":
        cmd = "moveUp";
        break;
      case "ctrl+down":
        cmd = "moveDown";
        break;
      case "ctrl+right":
      case "ctrl+shift+right": // mac
        cmd = "indent";
        break;
      case "ctrl+left":
      case "ctrl+shift+left": // mac
        cmd = "outdent";
      }
      if( cmd ){
        $(this).trigger("nodeCommand", {cmd: cmd});
        // e.preventDefault();
        // e.stopPropagation();
        return false;
      }
    });

    tree.$container.contextmenu({
      delegate: "span.fancytree-node",
      menu: [
        {title: "Edit <kbd>[F2]</kbd>", cmd: "rename", uiIcon: "ui-icon-pencil" },
        {title: "Delete <kbd>[Del]</kbd>", cmd: "remove", uiIcon: "ui-icon-trash" },
        {title: "----"},
        {title: "New sibling <kbd>[Ctrl+N]</kbd>", cmd: "addSibling", uiIcon: "ui-icon-plus" },
        {title: "New child <kbd>[Ctrl+Shift+N]</kbd>", cmd: "addChild", uiIcon: "ui-icon-arrowreturn-1-e" },
        {title: "----"},
        {title: "Cut <kbd>Ctrl+X</kbd>", cmd: "cut", uiIcon: "ui-icon-scissors"},
        {title: "Copy <kbd>Ctrl-C</kbd>", cmd: "copy", uiIcon: "ui-icon-copy"},
        {title: "Paste as child<kbd>Ctrl+V</kbd>", cmd: "paste", uiIcon: "ui-icon-CLIPBOARD.value", disabled: true }
        ],
      beforeOpen: function(event, ui) {
        var node = $.ui.fancytree.getNode(ui.target);
        tree.$container.contextmenu("enableEntry", "paste", !!CLIPBOARD.value);
        node.setActive();
      },
      select: function(event, ui) {
        var that = this;
        // delay the event, so the menu can close and the click event does
        // not interfere with the edit control
        setTimeout(function(){
          $(that).trigger("nodeCommand", {cmd: ui.cmd});
        }, 100);
      }
    });
  }
};
</script>

<style>
td.alignCenter {
  text-align: center;
}
table {
  margin-top: 20px;
}
table th {
  padding: 10px;
}
input.orderInput {
  width: 60px;
}
</style>
